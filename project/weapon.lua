local Weapon = {}

local function newDeadly(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, layer)
	local xOff, yOff = Misc.angleToDir(angle)
	local body = Body.new(x + xOff, y + yOff, world, health, mass, bounce, layer)
	body.speedPerHealth = 1
	body.speedThreshold = 0
	local bullet = {body = body, image = image, trailColour = trailColour}
	Body.impartForce(body, speed*mass, angle)
	body.minSpeed = minSpeed
	
	bullet.trackingLine = TrackingLines.new(body.x, body.y, body.angle, body, GlobalTurnTime, {1, 0, 0, 0.4}, world)
	
	if body.tile == nil then
		error("what")
	end
	
	body.destroyFunction = destroyFunction
	
	table.insert(world.bullets, bullet)
	return bullet
end

local function newBullet(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction)
	return newDeadly(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, "bullet")
end

local function newBomb(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction)
	return newDeadly(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, "bomb")
end

local weapons = {}
local function addWeapon(weaponName, fireFunc, weaponColour, bodyTemplate)
	local weapon = {weaponName = weaponName, fireFunc = fireFunc, weaponColour = weaponColour, printColumns = {}, bodyTemplate = bodyTemplate}
	
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

local function fireOverSpread(centerAngle, arc, nBullets, func)
	local segmentSize = arc/nBullets
	for i = 1, nBullets do
		local angle = centerAngle + segmentSize*(i - nBullets/2 - 0.5) + Random.randomBetweenPoints(-segmentSize/2, segmentSize/2)
		func(angle)
	end
end

do --initialize player weapons
	do --Bolt Caster
		local bulletSpeed = 40
		local simulationBody = Body.newRaw(20, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 20
		addWeapon("Bolt Caster", 
		function(x, y, targetX, targetY, firingBody, world)
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 5, angle + math.pi)
			newBullet(x, y, 20, 0.1, 0, world, bulletSpeed, angle, Image.letterToImage("-", {0.8, 0.8, 0.8, 1}), 20, {0.8, 0.6, 0, 0.8}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 2, 1, 20, 80, world)
			end)
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
	
	do --Force Wave
		addWeapon("Force Wave", 
		function(x, y, targetX, targetY, firingBody, world)
			Explosion.ring(x, y, 4, 1, 1, 20, 20, world)
		end, 
		{0.7, 0.7, 1, 1}, nil)
	end
	
	do --Hydrocarbon Explosive
		local bulletSpeed = 0
		local simulationBody = Body.newRaw(10, 1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 0
		addWeapon("Hydrocarbon Explosive", 
		function(x, y, targetX, targetY, firingBody, world)
			local angle = math.atan2(targetY - y, targetX - x)
			newBomb(x, y, 10, 1, 0, world, bulletSpeed, angle, Image.letterToImage("O", {0.8, 0, 0, 1}), 0, {0.4, 0, 0, 0.4}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 10, 2, 30, 1000, world)
			end)
		end, 
		{0.8, 0, 0, 1}, simulationBody)
	end
end

do --initialize enemy weapons
	do --Harpy Blaster
		local bulletSpeed = 30
		addWeapon("Harpy Blaster", 
		function(x, y, targetX, targetY, firingBody, world)
			local angle = math.atan2(targetY - y, targetX - x)
			fireOverSpread(angle, math.pi/3, 4,
			function(a)
				newBullet(x, y, 8, 0.1, 0, world, bulletSpeed, a, Image.letterToImage(".", {1, 1, 0, 1}), 15, {0.8, 0.8, 0, 0.8})
			end)
		end, 
		{0, 1, 0, 1}, nil)
	end
end

function Weapon.simulateFire(weaponName, x, y, targetX, targetY, world)
	local weapon = weapons[weaponName]
	if weapon.bodyTemplate then
		local angle = math.atan2(targetY - y, targetX - x)
		return TrackingLines.new(x, y, angle, weapon.bodyTemplate, GlobalTurnTime, {1, 0, 0, 0.4}, world)
	end
end

function Weapon.getPrintInfo(weaponName)
	local weapon = weapons[weaponName]
	return weapon.printColumns, weapon.weaponColour
end

function Weapon.getSimulationTemplate(weaponName)
	local weapon = weapons[weaponName]
	return weapon.bodyTemplate
end

function Weapon.prepareWeaponFire(weaponName, x, y, targetX, targetY, firingBody, world)
	local weapon = weapons[weaponName]
	local func = function()
		return weapon.fireFunc(x, y, targetX, targetY, firingBody, world)
	end
	return func
end

function Weapon.updateBullets(bullets, dt)
	local i = #bullets
	while i > 0 do
		local bullet = bullets[i]
		
		Tile.addTrail(bullet.body.tile, bullet.trailColour)
		
		if bullet.body.destroy then
			bullet.trackingLine.destroy = true
			table.remove(bullets, i)
		end
		i = i -1
	end
end

function Weapon.updateBulletTrajectories(bullets)
	for i = 1, #bullets do
		local bullet = bullets[i]
		TrackingLines.changeSpeed(bullet.trackingLine, bullet.body.speed)
		TrackingLines.updatePoints(bullet.trackingLine, bullet.body.x, bullet.body.y, bullet.body.angle)
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