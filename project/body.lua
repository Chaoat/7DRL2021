local Body = {}

local ID = 0
function Body.newRaw(health, mass, bounce, layer)
	local body = {x = nil, y = nil, health = health, maxHealth = health, mass = mass, bounce = bounce, speed = 0, angle = 0, tile = nil, map = nil, world = nil, inDanger = 0, layer = layer, ID = ID, moveCallBacks = {}, speedThreshold = 10, speedPerHealth = 5, parent = nil}
	ID = ID + 1
	return body
end

function Body.anchor(body)
	body.mass = 9999
	body.friction = 100
end

function Body.setInvincible(body)
	body.invincible = true
end

function Body.setBounceSound(body, soundName, volume, minDamage)
	if not minDamage then
		minDamage = 0
	end
	body.bounceSound = {Sound.newSound(soundName, volume), volume, minDamage}
end

function Body.setTracking(body, targetBody, force, targetSpeed)
	body.tracking = {targetBody = targetBody, force = force, targetSpeed = targetSpeed}
end

function Body.duplicateRaw(body)
	local copy = {}
	for key, value in pairs(body) do
		copy[key] = value
	end
	body.ID = ID
	ID = ID + 1
	return copy
end

function Body.new(x, y, world, health, mass, bounce, layer)
	local body = Body.newRaw(health, mass, bounce, layer)
	Body.placeInWorld(body, x, y, world)
	
	return body
end

function Body.placeInWorld(body, x, y, world)
	body.map = world.map
	body.world = world
	body.x = x
	body.y = y
	
	PhysicsSystem.addBody(world.physicsSystem, body)
	Body.move(body, x, y)
end

function Body.addMoveCallback(body, func)
	--func(oldTile)
	table.insert(body.moveCallBacks, func)
end

function Body.impartForce(body, force, angle)
	local nEnergy, nAngle = Vector.addVectors(body.speed*body.mass, body.angle, force, angle)
	body.speed = nEnergy/body.mass
	body.angle = nAngle
end

function Body.update(body, dt, ignoreCollisions)
	local nextX = body.x + dt*body.speed*math.cos(body.angle)
	local nextY = body.y + dt*body.speed*math.sin(body.angle)
	
	if body.friction and body.tile.floored then
		body.speed = body.speed*math.max((1 - dt*body.friction), 0)
	end
	
	if not Body.move(body, nextX, nextY, ignoreCollisions) then
		--Body.update(body, dt)
	end
	
	if body.tracking then
		local targetBody = body.tracking.targetBody
		local targetDistance = math.sqrt((targetBody.x - body.x)^2 + (targetBody.y - body.y)^2)
		local targetAngle = math.atan2(targetBody.y - body.y, targetBody.x - body.x)
		
		local targetSpeed = body.tracking.targetSpeed
		local speedTo, angleTo = PhysicsSystem.findVectorBetween(body.speed, body.angle, targetSpeed, targetAngle)
		
		Body.impartForce(body, math.min(speedTo*body.mass, body.tracking.force*dt), angleTo)
	end
	
	if body.minSpeed then
		if body.speed < body.minSpeed then
			Body.destroy(body)
		end
	end
	
	if body.duration then
		if body.duration <= 0 then
			Body.destroy(body)
		else
			body.duration = body.duration - dt
		end
	end
end

function Body.destroy(body)
	if not body.destroy then
		body.destroy = true
		
		if not body.simulation and body.destroyFunction then
			body.destroyFunction(body)
		end
		if body.tile then
			Map.addTileToCleanQueue(body.map, body.tile, body.layer)
		end
	end
end

function Body.damage(body, damage, angle)
	if not body.simulation and body.bounceSound and damage >= body.bounceSound[3] then
		Sound.updateVolume(body.bounceSound, body.x, body.y)
		body.bounceSound[1]:seek(0)
		body.bounceSound[1]:play()
		
		if body.player then
			globalGame.transition = ScreenTransitions.redFlash()
		end
	end
	
	if not body.invincible then
		if damage > 5 and not body.simulation then			
			if body.bloody then
				Particle.bloodBurst(body.x, body.y, angle, damage, body.world)
			elseif body.sparky then
				Particle.sparkBurst(body.x, body.y, angle, damage, body.world)
			end
		end
		
		body.health = body.health - damage
		if body.health <= 0 then
			body.health = 0
			Body.destroy(body)
		end
		Enemy.shout(body, 1, damage)
	end
end

function Body.move(body, newX, newY, ignoreCollisions)
	if not body.destroy then
		local oldTile = body.tile
		local nextTile = Map.getTile(body.map, newX, newY)
		
		local collided = false
		if not Tile.compare(nextTile, oldTile) then
			local map = body.map
			if PhysicsSystem.processCollision(body, newX, newY, nextTile, ignoreCollisions) then
				if oldTile then
					collided = true
				else
					body.tile = nextTile
					Tile.addBody(nextTile, body)
				end
			else
				if oldTile then
					Map.addTileToCleanQueue(map, oldTile, body.layer)
				end
				body.tile = nextTile
				Tile.addBody(nextTile, body)
				
				for i = 1, #body.moveCallBacks do
					body.moveCallBacks[i](oldTile)
				end
			end
		end
		
		if not collided then
			body.x = newX
			body.y = newY
			return true
		else
			return false
		end
	end
end

function Body.debugDrawBodies(bodies, camera)
	for i = 1, #bodies do
		local body = bodies[i]
		love.graphics.setColor(body.speed/100, (body.angle%(2*math.pi))/2*math.pi, 0, 0.7)
		Camera.drawTo(camera, body.x, body.y, function(drawX, drawY)
			--love.graphics.circle("fill", drawX, drawY, 7)
			love.graphics.print(math.ceil(body.speed), drawX, drawY)
			if body.simulation then
				love.graphics.circle("fill", drawX, drawY, 4)
			end
		end)
	end
end

return Body