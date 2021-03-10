local PhysicsSystem = {}

function PhysicsSystem.new(turnDuration)
	local physicsSystem = {bodies = {}, fastestSpeed = 0}
	return physicsSystem
end

function PhysicsSystem.addBody(physicsSystem, body)
	--print("ID: " .. body.ID)
	
	table.insert(physicsSystem.bodies, body)
end

function PhysicsSystem.determineFastestSpeed(physicsSystem)
	physicsSystem.fastestSpeed = 0
	for i = 1, #physicsSystem.bodies do
		local body = physicsSystem.bodies[i]
		physicsSystem.fastestSpeed = math.max(physicsSystem.fastestSpeed, body.speed)
	end
	--print(physicsSystem.fastestSpeed)
	--print(#physicsSystem.bodies)
end

function PhysicsSystem.update(world, dt)
	local pS = world.physicsSystem
	local i = #pS.bodies
	while i > 0 do
		Body.update(pS.bodies[i], dt)
		if pS.bodies[i].destroy then
			table.remove(pS.bodies, i)
		end
		i = i - 1
	end
	
	Explosion.updateExplosions(world.explosions, dt)
	Weapon.updateBullets(world.bullets, dt)
	
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
				return negAngle
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

function PhysicsSystem.processCollision(body, newX, newY, tile, ignoreCollisions)
	local collidingLayers = Layers.getCollidingLayers(body.layer)
	
	local colliders = {}
	for i = 1, #collidingLayers do
		for j = 1, #tile.bodies[collidingLayers[i]] do
			if not tile.bodies[collidingLayers[i]][j].simulation then
				table.insert(colliders, tile.bodies[collidingLayers[i]][j])
			end
		end
	end
	
	if #colliders > 0 then
		local totalEnergy = 0
		local totalAngle = 0
		local totalMass = 0
		local totalHealth = 0
		local totalDamage = 0
		local averageBounce = body.bounce
		for i = 1, #colliders do
			local collider = colliders[i]
			totalEnergy, totalAngle = Vector.addVectors(totalEnergy, totalAngle, collider.speed*collider.mass, collider.angle)
			averageBounce = averageBounce + collider.bounce
			totalMass = totalMass + collider.mass
			totalHealth = totalHealth + collider.health
			totalDamage = totalDamage + (collider.speed - collider.speedThreshold)/collider.speedPerHealth
		end
		averageBounce = averageBounce/(#colliders + 1)
		
		local incident = findIncident(body, newX, newY, tile)
		
		local totalEnergyInAngle = math.max(PhysicsSystem.findVectorInAngle(totalEnergy, totalAngle, incident), 0)
		totalDamage = math.min(math.max(PhysicsSystem.findVectorInAngle(totalDamage, totalAngle, incident), 0), totalHealth)
		local bodyEnergyInAngle = math.max(PhysicsSystem.findVectorInAngle(body.speed*body.mass, body.angle, incident + math.pi), 0)
		local bodyDamage = math.min((bodyEnergyInAngle/body.mass - body.speedThreshold)/body.speedPerHealth, body.health)
		
		if totalDamage > body.health then
			totalEnergyInAngle = totalEnergyInAngle*(body.health/totalDamage)
		elseif bodyDamage > totalHealth then
			bodyEnergyInAngle = bodyEnergyInAngle*(totalHealth/bodyDamage)
		end
		
		if not body.simulation and not ignoreCollisions then
			for i = 1, #colliders do
				local collider = colliders[i]
				local ratio = collider.mass/totalMass
				--collider.speed = collider.speed - (bodyEnergyInAngle/collider.mass)*ratio
				--collider.angle = flipAngleOverIncident(collider.angle, incident)
				Body.impartForce(collider, (1 + averageBounce)*collider.mass*math.max(PhysicsSystem.findVectorInAngle(collider.speed, collider.angle, incident), 0), incident + math.pi)
				Body.impartForce(collider, (1 - averageBounce)*ratio*bodyEnergyInAngle, body.angle)
				Body.damage(collider, bodyDamage*ratio)
				Body.damage(collider, totalDamage*ratio)
			end
		end
		
		--body.speed = body.speed*averageBounce
		--body.angle = flipAngleOverIncident(body.angle + math.pi, incident)
		--print(incident/math.pi .. " : " .. bodyEnergyInAngle .. " : " .. body.layer)
		Body.impartForce(body, (1 + averageBounce)*bodyEnergyInAngle, incident)
		Body.impartForce(body, (1 - averageBounce)*totalEnergyInAngle, totalAngle)
		Body.damage(body, totalDamage)
		Body.damage(body, bodyDamage)
		
		return true
	end
	return false
end

return PhysicsSystem