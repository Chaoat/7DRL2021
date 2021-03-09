local Explosion = {}

function Explosion.explode(x, y, radius, damage, world)
	local nParticles = math.ceil(2*radius*math.pi)
	local partDamage = damage/nParticles
	local speed = 20
	local mass = 10
	for i = 1, nParticles do
		local angle = 2*math.pi*(i/nParticles)
		local particle = Body.new(x, y, world, partDamage, mass, 1, "explosion")
		Body.impartForce(particle, speed*mass, angle)
		particle.duration = radius/speed
	end
end

return Explosion