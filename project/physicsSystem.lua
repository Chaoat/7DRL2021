local PhysicsSystem = {}

function PhysicsSystem.new(turnDuration)
	local physicsSystem = {bodies = {}, fastestSpeed = 0}
	return physicsSystem
end

function PhysicsSystem.addBody(physicsSystem, body)
	table.insert(physicsSystem.bodies, body)
end

function PhysicsSystem.determineFastestSpeed(physicsSystem)
	physicsSystem.fastestSpeed = 0
	for i = 1, #physicsSystem.bodies do
		local body = physicsSystem.bodies[i]
		physicsSystem.fastestSpeed = math.max(physicsSystem.fastestSpeed, body.speed)
	end
end

function PhysicsSystem.update(world, dt)
	local pS = world.physicsSystem
	for i = 1, #pS.bodies do
		Body.update(pS.bodies[i], dt)
	end
	Map.cleanAllTiles(world.map)
end

local function findIncident(body, newX, newY, tile)
	local bodyAngle = math.atan2(body.y - tile.y, body.x - tile.x)
	local newAngle = math.atan2(newY - tile.y, newX - tile.x)
	local function checkQuadrant(quadAngle)
		if Misc.distBetweenAngles(quadAngle, bodyAngle) <= math.pi/4 then
			local addAngle = quadAngle + math.pi/4
			local negAngle = quadAngle - math.pi/4
			local addDiff = Misc.distBetweenAngles(addAngle, newAngle)
			local negDiff = Misc.distBetweenAngles(negAngle, newAngle)
			
			if addDiff > negDiff then
				return addAngle
			else
				return negDiff
			end
		end
		return false
	end
	if body.x >= tile.x - 0.5 and body.x <= tile.x + 0.5 and body.y <= tile.y then
		if body.y <= tile.y then
			return -math.pi/2
		else
			return math.pi/2
		end
	elseif body.y >= tile.y - 0.5 and body.y <= tile.y + 0.5 then
		if body.x <= tile.x then
			return math.pi
		else
			return 0
		end
	else
		return checkQuadrant(math.pi/4) or checkQuadrant(3*math.pi/4) or checkQuadrant(-math.pi/4) or checkQuadrant(-3*math.pi/4)
	end
end

local function flipAngleOverIncident(angle, incident)
	local incidentDiff = incident - angle
	return Misc.simplifyAngle(incident + incidentDiff)
end

function PhysicsSystem.processCollision(body, newX, newY, tile)
	local collidingLayers = Layers.getCollidingLayers(body.layer)
	
	local colliders = {}
	for i = 1, #collidingLayers do
		for j = 1, #tile.bodies[collidingLayers[i]] do
			table.insert(colliders, tile.bodies[collidingLayers[i]][j])
		end
	end
	
	if #colliders > 0 then
		local totalEnergy = 0
		local totalAngle = 0
		local totalMass = 0
		local averageBounce = body.bounce
		for i = 1, #colliders do
			local collider = colliders[i]
			totalEnergy, totalAngle = Vector.addVectors(totalEnergy, totalAngle, collider.speed*collider.mass, collider.angle)
			averageBounce = averageBounce + collider.bounce
			totalMass = totalMass + collider.mass
		end
		averageBounce = averageBounce/(#colliders + 1)
		
		local incident = findIncident(body, newX, newY, tile)
		
		for i = 1, #colliders do
			local collider = colliders[i]
			local ratio = collider.mass/totalMass
			collider.speed = collider.speed*averageBounce
			collider.angle = flipAngleOverIncident(collider.angle, incident)
			Body.impartForce(collider, (1 - averageBounce)*ratio*body.speed*body.mass, body.angle)
		end
		
		body.speed = body.speed*averageBounce
		body.angle = flipAngleOverIncident(body.angle + math.pi, incident)
		Body.impartForce(body, (1 - averageBounce)*totalEnergy, totalAngle)
		
		return true
	end
	return false
end

return PhysicsSystem