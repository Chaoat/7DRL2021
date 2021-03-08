local TurnCalculation = {}

function TurnCalculation.newSystem(turnDuration)
	local turnSystem = {turnDuration = turnDuration, turnLeft = 0, stepSize = 0, turnRunning = false}
	return turnSystem
end

function TurnCalculation.runTurn(turnSystem, world)
	print("--new turn--")
	if not turnSystem.turnRunning then
		local pS = world.physicsSystem
		
		PhysicsSystem.determineFastestSpeed(world.physicsSystem)
		
		local stepSize = turnSystem.turnDuration
		if pS.fastestSpeed > 0 then
			stepSize = 1/pS.fastestSpeed
		end
		turnSystem.stepSize = stepSize
		
		turnSystem.turnRunning = true
		
		turnSystem.turnLeft = turnSystem.turnDuration
		
		local b1 = Body.new(0, 10, world, 1, 1, 0, "bullet")
		Body.impartForce(b1, 20, -math.pi/4)
	end
end

function TurnCalculation.updateTurn(turnSystem, world, dt)
	dt = math.min(turnSystem.turnLeft, dt)
	
	local stepTime = math.min(dt, turnSystem.stepSize)
	while stepTime > 0 do
		local thisStep = math.min(stepTime, turnSystem.stepSize)
		PhysicsSystem.update(world, dt)
		stepTime = stepTime - thisStep
	end
	
	turnSystem.turnLeft = turnSystem.turnLeft - dt
	if turnSystem.turnLeft <= 0 then
		turnSystem.turnRunning = false
	end
end

return TurnCalculation