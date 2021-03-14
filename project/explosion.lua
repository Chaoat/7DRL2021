local Explosion = {}

local function newParticle(x, y, radius, angle, damage, mass, speed, colour1, colour2, bounce, world)
	local body = Body.new(x, y, world, damage, mass, bounce, "explosion")
	body.speedPerHealth = 1
	body.speedThreshold = 0
	local particle = {body = body, tileColour = TileColour.new(colour1, colour2, radius/speed)}
	Body.impartForce(body, speed*mass, angle)
	body.duration = radius/math.abs(speed)
	
	local xOff, yOff = Misc.angleToOffset(body.angle, 1)
	particle.trackingLine = TrackingLines.new(body.x, body.y, body.x + xOff, body.y + yOff, body, GlobalTurnTime, {1, 0, 0, 0.4}, world)
	table.insert(world.explosions, particle)
	return particle
end

function Explosion.colouredExplosion(x, y, radius, mass, speed, damage, world, colour1, colour2)
	local nParticles = 3*math.ceil(2*radius*math.pi)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		newParticle(x, y, radius, angle, partDamage, mass, speed, colour1, colour2, 1, world)
	end
end

function Explosion.explode(x, y, radius, mass, speed, damage, world)
	Explosion.colouredExplosion(x, y, radius, mass, speed, damage, world, {1, 1, 0.8, 1}, {1, 0.5, 0.1, 0.7})
end

function Explosion.ring(x, y, radius, ringSize, mass, speed, damage, world)
	local nParticles = 3*math.ceil(2*(radius + ringSize)*math.pi)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		local rX = Misc.round(x + ringSize*math.cos(angle))
		local rY = Misc.round(y + ringSize*math.sin(angle))
		newParticle(rX, rY, radius, angle, partDamage, mass, speed, {0.9, 0.9, 1, 0.8}, {0.4, 0.4, 0.5, 0.4}, 0, world)
	end
end

function Explosion.targettedBlast(x, y, radius, angle, width, mass, speed, damage, world)
	local nParticles = 3*math.ceil(radius*width)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = angle + width*(-0.5 + i/nParticles)
		local rX = x
		local rY = y
		newParticle(rX, rY, radius, angle, partDamage, mass, speed, {0.9, 0.9, 1, 0.8}, {0.4, 0.4, 0.5, 0.4}, 1, world)
	end
end

function Explosion.targettedExplosion(x, y, radius, angle, width, mass, speed, damage, world)
	local nParticles = 3*math.ceil(radius*width)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = angle + width*(-0.5 + i/nParticles)
		local rX = x
		local rY = y
		newParticle(rX, rY, radius, angle, partDamage, mass, speed, {1, 1, 0.8, 1}, {1, 0.5, 0.1, 0.7}, 1, world)
	end
end

function Explosion.updateExplosions(explosions, dt)
	local i = #explosions
	while i > 0 do
		local explosion = explosions[i]
		if explosion.body.tile.floored then
			Tile.damage(explosion.body.tile, 20*explosion.body.health*dt, explosion.body.world)
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
		if explosion.trackingLine then
			TrackingLines.changeSpeed(explosion.trackingLine, explosion.body.speed)
			local xOff, yOff = Misc.angleToOffset(explosion.body.angle, 1)
			TrackingLines.updatePoints(explosion.trackingLine, explosion.body.x, explosion.body.y, explosion.body.x + xOff, explosion.body.y + yOff)
		end
	end
end

function Explosion.drawExplosions(explosions, camera)
	for i = 1, #explosions do
		local explosion = explosions[i]
		TileColour.draw(explosion.tileColour, explosion.body.tile, camera)
	end
end

return Explosion