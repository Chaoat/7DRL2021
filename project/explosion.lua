local Explosion = {}

function Explosion.explode(x, y, radius, mass, speed, damage, world)
	local nParticles = math.ceil(2*radius*math.pi)
	local partDamage = damage/nParticles
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		local body = Body.new(x, y, world, partDamage, mass, 1, "explosion")
		local particle = {body = body, tileColour = TileColour.new({1, 1, 0.8, 1}, {1, 0.5, 0.1, 0.7}, radius/speed)}
		Body.impartForce(body, speed*mass, angle)
		body.duration = radius/speed
		table.insert(world.explosions, particle)
	end
end

function Explosion.updateExplosions(explosions, dt)
	local i = #explosions
	while i > 0 do
		local explosion = explosions[i]
		if explosion.body.tile.floored then
			Tile.damage(explosion.body.tile, explosion.body.health*dt)
		end
		
		TileColour.update(explosion.tileColour, dt)
		
		if explosion.body.destroy then
			table.remove(explosions, i)
		end
		i = i - 1
	end
end

function Explosion.drawExplosions(explosions, camera)
	for i = 1, #explosions do
		local explosion = explosions[i]
		TileColour.draw(explosion.tileColour, explosion.body.tile, camera)
	end
end

return Explosion