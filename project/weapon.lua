local Weapon = {}

local function newBullet(x, y, health, mass, bounce, world, speed, angle, minSpeed, destroyFunction)
	local xOff, yOff = Misc.angleToDir(angle)
	local bullet = Body.new(x + xOff, y + yOff, world, health, mass, bounce, "bullet")
	Body.impartForce(bullet, speed*mass, angle)
	bullet.minSpeed = minSpeed
	
	bullet.destroyFunction = destroyFunction
	
	table.insert(world.bullets, bullet)
	return bullet
end

function Weapon.boltCaster(x, y, targetX, targetY, world)
	local angle = math.atan2(targetY - y, targetX - x)
	newBullet(x, y, 1, 0.1, 0, world, 40, angle, 20, function(bullet)
		Explosion.explode(bullet.x, bullet.y, 2, 20, world)
	end)
end

return Weapon