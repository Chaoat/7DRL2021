local Particle = {}

function Particle.new(x, y, speed, angle, friction, colour1, colour2, duration, world)
	local body = Body.new(x, y, world, 0, 1, 1, "particle")
	body.simulation = true
	Body.setInvincible(body)
	body.friction = friction
	local particle = {body = body, colour1 = colour1, colour2 = colour2, timeLeft = duration, duration = duration, lastDraw = GlobalClock}
	Body.impartForce(body, speed, angle)
	table.insert(world.particles, particle)
	return particle
end

function Particle.updateAll(particles, dt)
	for i = 1, #particles do
		local particle = particles[i]
		particle.timeLeft = math.max(particle.timeLeft - dt, 0)
	end
end

function Particle.drawAll(particles, camera)
	local i = #particles
	while i > 0 do
		local particle = particles[i]
		
		local ratio = particle.timeLeft/particle.duration
		local colour = Misc.blendColours(particle.colour2, particle.colour1, ratio)
		if particle.body.tile.visible then
			Camera.drawTo(camera, particle.body.tile.x, particle.body.tile.y, function(drawX, drawY)
				love.graphics.setColor(colour)
				love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
			end)
		end
		
		if particle.timeLeft == 0 then
			if particle.residue then
				Misc.addColours(particle.body.tile.tileColour, colour)
			end
			Body.destroy(particle.body)
			table.remove(particles, i)
		end
		
		i = i - 1
	end
end

function Particle.bloodBurst(x, y, angle, damage, world)
	local nParticles = 4*math.ceil(math.sqrt(damage))
	local speedRange = {0, damage}
	local angleRange = {-math.pi/2, math.pi/2}
	for i = 1, nParticles do
		local speed = Random.randomBetweenPoints(speedRange[1], speedRange[2])
		local angle = Random.randomBetweenPoints(angleRange[1], angleRange[2])
		
		local randColour = Misc.blendColours({0.5, 0, 0, 0.5}, {0.2, 0, 0, 0.5}, math.random())
		
		local particle = Particle.new(x, y, speed, angle, 3, randColour, {0.2, 0, 0, 0.1}, 2, world)
		particle.residue = true
	end
end

function Particle.sparkBurst(x, y, angle, damage, world)
	local nParticles = 3
	local speedRange = {0, 15}
	local angleRange = {-math.pi/3, math.pi/3}
	for i = 1, nParticles do
		local speed = Random.randomBetweenPoints(speedRange[1], speedRange[2])
		local angle = Random.randomBetweenPoints(angleRange[1], angleRange[2])
		
		local randColour = Misc.blendColours({1, 1, 0, 0.5}, {1, 1, 1, 0.5}, math.random())
		
		Particle.new(x, y, speed, angle, 0, randColour, randColour, 0.15, world)
	end
end

return Particle