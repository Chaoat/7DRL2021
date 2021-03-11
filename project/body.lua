local Body = {}

local ID = 0
function Body.newRaw(health, mass, bounce, layer)
	local body = {x = nil, y = nil, health = health, maxHealth = health, mass = mass, bounce = bounce, speed = 0, angle = 0, tile = nil, map = nil, world = nil, layer = layer, ID = ID, moveCallBacks = {}, speedThreshold = 10, speedPerHealth = 10, parent = nil}
	ID = ID + 1
	return body
end

function Body.anchor(body)
	body.mass = 99999
	body.friction = 100
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
	
	if body.friction then
		body.speed = body.speed*math.max((1 - dt*body.friction), 0)
	end
	
	if not Body.move(body, nextX, nextY, ignoreCollisions) then
		--Body.update(body, dt)
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

function Body.damage(body, damage)
	body.health = body.health - damage
	if body.health <= 0 then
		body.health = 0
		Body.destroy(body)
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
			love.graphics.circle("fill", drawX, drawY, 7)
		end)
	end
end

return Body