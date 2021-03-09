local Body = {}

local ID = 0
function Body.new(x, y, world, health, mass, bounce, layer)
	local body = {x = x, y = y, health = health, mass = mass, bounce = bounce, speed = 0, angle = 0, tile = nil, map = world.map, world = world, layer = layer, ID = ID, moveCallBacks = {}}
	ID = ID + 1
	PhysicsSystem.addBody(world.physicsSystem, body)
	
	Body.move(body, x, y)
	
	return body
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

function Body.update(body, dt)
	local nextX = body.x + dt*body.speed*math.cos(body.angle)
	local nextY = body.y + dt*body.speed*math.sin(body.angle)
	
	if body.friction then
		body.speed = body.speed*(1 - dt*body.friction)
	end
	
	if not Body.move(body, nextX, nextY) then
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
		if body.destroyFunction then
			body.destroyFunction(body)
		end
		body.destroy = true
		if body.tile then
			Map.addTileToCleanQueue(body.map, body.tile, body.layer)
		end
	end
end

function Body.move(body, newX, newY)
	local oldTile = body.tile
	local nextTile = Map.getTile(body.map, newX, newY)
	
	local collided = false
	if not Tile.compare(nextTile, oldTile) then
		local map = body.map
		if PhysicsSystem.processCollision(body, newX, newY, nextTile) then
			collided = true
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