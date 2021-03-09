local Weapon = {}

local function newBullet(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, destroyFunction)
	local xOff, yOff = Misc.angleToDir(angle)
	local body = Body.new(x + xOff, y + yOff, world, health, mass, bounce, "bullet")
	local bullet = {body = body, image = image}
	Body.impartForce(body, speed*mass, angle)
	body.minSpeed = minSpeed
	
	body.destroyFunction = destroyFunction
	
	table.insert(world.bullets, bullet)
	return bullet
end

local weapons = {}
local function addWeapon(weaponName, fireFunc, weaponColour, bodyTemplate)
	local weapon = {weaponName = weaponName, fireFunc = fireFunc, weaponColour = weaponColour, printColumns = {}, fireSpeed = fireSpeed, bodyTemplate = bodyTemplate}
	
	local lastCapital = 1
	for i = 2, #weaponName do
		local character = weaponName:sub(i, i)
		local asciiCode = string.byte(character)
		if asciiCode >= 65 and asciiCode <= 90 then
			table.insert(weapon.printColumns, weaponName:sub(lastCapital, i - 1))
			lastCapital = i
		end
	end
	table.insert(weapon.printColumns, weaponName:sub(lastCapital, #weaponName))

	weapons[weaponName] = weapon
end

do --initialize weapons
	do --Bolt Caster
		local bulletSpeed = 40
		local simulationBody = Body.newRaw(1, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 20
		addWeapon("Bolt Caster", 
		function(x, y, targetX, targetY, world)
			local angle = math.atan2(targetY - y, targetX - x)
			newBullet(x, y, 1, 0.1, 0, world, bulletSpeed, angle, Image.letterToImage("-", {0, 0.8, 0, 1}, 20, 20), 20, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 2, 20, world)
			end)
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
end

function Weapon.simulateFire(weaponName, x, y, targetX, targetY, world)
	local weapon = weapons[weaponName]
	local angle = math.atan2(targetY - y, targetX - x)
	return TrackingLines.new(x, y, angle, weapon.bodyTemplate, GlobalTurnTime, world)
end

function Weapon.getPrintInfo(weaponName)
	local weapon = weapons[weaponName]
	return weapon.printColumns, weapon.weaponColour
end

function Weapon.prepareWeaponFire(weaponName, x, y, targetX, targetY, world)
	local weapon = weapons[weaponName]
	local func = function()
		return weapon.fireFunc(x, y, targetX, targetY, world)
	end
	return func
end

function Weapon.updateBullets(bullets, dt)
	local i = #bullets
	while i > 0 do
		local bullet = bullets[i]
		
		Tile.addTrail(bullet.body.tile, {1, 0, 0, 1})
		
		if bullet.body.destroy then
			table.remove(bullets, i)
		end
		i = i -1
	end
end

function Weapon.drawBullets(bullets, camera)
	for i = 1, #bullets do
		local bullet = bullets[i]
		if bullet.body.tile.visible then
			Image.drawImage(bullet.image, camera, bullet.body.x, bullet.body.y, bullet.body.angle)
		end
	end
end

return Weapon