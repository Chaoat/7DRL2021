local Shield = {}

function Shield.new(x, y, radius, world)
	local nParticles = 4*math.ceil(2*radius*math.pi)
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		local sX = x + radius*math.cos(angle)
		local sY = y + radius*math.sin(angle)
		local body = Body.new(sX, sY, world, 0, 0, 2, "shield")
		body.speedThreshold = 999999
		Body.anchor(body)
		Body.setInvincible(body)
		
		local shield = {body = body, tileColour = TileColour.new({0, 1, 1, 1}, {0, 1, 1, 1}, nil)}
		
		Body.setBounceSound(shield.body, "Shield.ogg", 0.3, 0)
		
		table.insert(world.shields, shield)
	end
end

function Shield.drawShields(shields, camera)
	for i = 1, #shields do
		local shield = shields[i]
		shield.tileColour.colour1[1] = Misc.oscillateBetween(0, 1, 0.3)
		TileColour.draw(shield.tileColour, shield.body.tile, camera)
	end
end

return Shield