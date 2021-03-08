local Body = {}

local ID = 0
function Body.new(x, y, world, health, mass, bounce, layer)
	local body = {x = x, y = y, health = health, mass = mass, bounce = bounce, speed = 0, angle = 0, tile = nil, map = world.map, layer = layer, ID = ID}
	ID = ID + 1
	PhysicsSystem.addBody(world.physicsSystem, body)
	
	Body.move(body, x, y)
	
	return body
end

function Body.impartForce(body, force, angle)
	local nEnergy, nAngle = PhysicsSystem.addVectors(body.speed*body.mass, body.angle, force, angle)
	body.speed = nEnergy/body.mass
	body.angle = nAngle
end

function Body.update(body, dt)
	local nextX = body.x + dt*body.speed*math.cos(body.angle)
	local nextY = body.y + dt*body.speed*math.sin(body.angle)
	
	Body.move(body, nextX, nextY)
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
		end
	end
	
	if not collided then
		body.x = newX
		body.y = newY
	end
end

function Body.debugDrawBodies(bodies, camera)
	love.graphics.setColor(0, 1, 0, 0.7)
	for i = 1, #bodies do
		local body = bodies[i]
		Camera.drawTo(camera, body.x, body.y, function(drawX, drawY)
			love.graphics.circle("fill", drawX, drawY, 7)
		end)
	end
end

return Body