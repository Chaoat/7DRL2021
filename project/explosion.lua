local Explosion = {}

local function newParticle(x, y, radius, angle, damage, mass, speed, colour1, colour2, world)
	local body = Body.new(x, y, world, damage, mass, 1, "explosion")
	body.speedPerHealth = 1
	body.speedThreshold = 0
	local particle = {body = body, tileColour = TileColour.new(colour1, colour2, radius/speed)}
	Body.impartForce(body, speed*mass, angle)
	body.duration = radius/speed
	
	particle.trackingLine = TrackingLines.new(body.x, body.y, body.angle, body, GlobalTurnTime, {1, 0, 0, 0.4}, world)
	table.insert(world.explosions, particle)
	return particle
end

function Explosion.explode(x, y, radius, mass, speed, damage, world)
	local nParticles = 3*math.ceil(2*radius*math.pi)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		newParticle(x, y, radius, angle, partDamage, mass, speed, {1, 1, 0.8, 1}, {1, 0.5, 0.1, 0.7}, world)
	end
end

function Explosion.ring(x, y, radius, ringSize, mass, speed, damage, world)
	local nParticles = 3*math.ceil(2*radius*math.pi)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		local rX = Misc.round(x + ringSize*math.cos(angle))
		local rY = Misc.round(y + ringSize*math.sin(angle))
		newParticle(rX, rY, radius, angle, partDamage, mass, speed, {0.9, 0.9, 1, 0.8}, {0.4, 0.4, 0.5, 0.4}, world)
	end
end

function Explosion.updateExplosions(explosions, dt)
	local i = #explosions
	while i > 0 do
		local explosion = explosions[i]
		if explosion.body.tile.floored then
			Tile.damage(explosion.body.tile, 20*explosion.body.health*dt)
		end
		
		TileColour.update(explosion.tileColour, dt)
		
		if explosion.body.destroy then
			explosion.trackingLine.destroy = true
			table.remove(explosions, i)
		end
		i = i - 1
	end
end


function Explosion.updateTrajectories(explosions)
	for i = 1, #explosions do
		local explosion = explosions[i]
		TrackingLines.changeSpeed(explosion.trackingLine, explosion.body.speed)
		TrackingLines.updatePoints(explosion.trackingLine, explosion.body.x, explosion.body.y, explosion.body.angle)
	end
end

function Explosion.drawExplosions(explosions, camera)
	for i = 1, #explosions do
		local explosion = explosions[i]
		TileColour.draw(explosion.tileColour, explosion.body.tile, camera)
	end
end

return Explosion