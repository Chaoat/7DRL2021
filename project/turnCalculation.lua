local TurnCalculation = {}

function TurnCalculation.newSystem(turnDuration)
	local turnSystem = {turnDuration = turnDuration, weaponDischarges = {}, turnLeft = 0, stepSize = 0, turnRunning = false}
	return turnSystem
end

function TurnCalculation.addWeaponDischarge(func, triggerTime, turnSystem)
	Misc.binaryInsert(turnSystem.weaponDischarges, {triggerTime = triggerTime, func = func}, "triggerTime")
end

local function calculateStepSize(turnSystem, world)
	local pS = world.physicsSystem
	
	PhysicsSystem.determineFastestSpeed(pS)
	
	local stepSize = turnSystem.turnDuration
	if pS.fastestSpeed > 0 then
		stepSize = 1/pS.fastestSpeed
	end
	turnSystem.stepSize = stepSize
end

function TurnCalculation.runTurn(turnSystem, world)
	print("--new turn--")
	if not turnSystem.turnRunning then
		local pS = world.physicsSystem
		
		calculateStepSize(turnSystem, world)
		
		turnSystem.turnRunning = true
		
		turnSystem.turnLeft = turnSystem.turnDuration
		
		--local b1 = Body.new(0, 10, world, 1, 1, 0, "bullet")
		--Body.impartForce(b1, 20, -math.pi/4)
	end
end

function TurnCalculation.updateTurn(game, dt)
	local world = game.world
	local turnSystem = game.turnSystem
	
	if turnSystem.turnRunning then
		if turnSystem.stepSize > 0.05 then
			dt = turnSystem.stepSize
		end
		dt = math.min(turnSystem.turnLeft, dt)
		
		local stepTime = dt
		while stepTime > 0 do
			local thisStep = math.min(stepTime, turnSystem.stepSize)
			
			for i = 1, #world.characters do
				Character.update(world.characters[i], turnSystem.turnLeft, thisStep)
			end
			
			PhysicsSystem.update(world, thisStep)
			
			stepTime = stepTime - thisStep
		end
		
		turnSystem.turnLeft = turnSystem.turnLeft - dt
		
		local newBodies = false
		while #turnSystem.weaponDischarges > 0 and turnSystem.weaponDischarges[1].triggerTime <= turnSystem.turnDuration - turnSystem.turnLeft do
			newBodies = true
			turnSystem.weaponDischarges[1].func()
			table.remove(turnSystem.weaponDischarges, 1)
		end
		if newBodies then
			calculateStepSize(turnSystem, world)
		end
		
		if turnSystem.turnLeft <= 0 then
			TurnCalculation.endTurn(game)
		end
	end
end

function TurnCalculation.endTurn(game)
	local world = game.world
	local turnSystem = game.turnSystem
	local player = game.player
	
	for i = 1, #turnSystem.weaponDischarges do
		turnSystem.weaponDischarges[i].triggerTime = turnSystem.weaponDischarges[i].triggerTime - turnSystem.turnDuration
	end
	turnSystem.turnRunning = false
end

return TurnCalculation