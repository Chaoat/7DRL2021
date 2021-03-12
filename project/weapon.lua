local Weapon = {}

local function newDeadly(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, layer)
	local xOff, yOff = Misc.angleToDir(angle)
	local tile = Map.getTile(world.map, x + xOff, y + yOff)
	if Tile.checkBlocking(tile, layer) then
		xOff = 0
		yOff = 0
	end
	local body = Body.new(x + xOff, y + yOff, world, health, mass, bounce, layer)
	body.speedPerHealth = 1
	body.speedThreshold = 0
	local bullet = {body = body, image = image, trailColour = trailColour}
	Body.impartForce(body, speed*mass, angle)
	body.minSpeed = minSpeed
	
	local xOff, yOff = Misc.angleToOffset(body.angle, 1)
	bullet.trackingLine = TrackingLines.new(body.x, body.y, body.x + xOff, body.y + yOff, body, GlobalTurnTime, {1, 0, 0, 0.4}, world)
	
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

local weaponDescriptions = {}
local function addWeaponDescription(name, description)
	weaponDescriptions[name] = description
end
function Weapon.getWeaponDescription(name)
	return weaponDescriptions[name]
end

do --initialize player weapons
	do --Bolt Caster
		local bulletSpeed = 40
		local simulationBody = Body.newRaw(20, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 20
		addWeapon("Bolt Caster", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 5, angle + math.pi)
			newBullet(x, y, 8, 0.1, 0, world, bulletSpeed, angle, Image.letterToImage("-", {0.8, 0.8, 0.8, 1}), 20, {0.8, 0.6, 0, 0.8}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 2, 0.4, 20, 70, world)
			end)
		end, 
		{0, 1, 0, 1}, simulationBody)
		
		addWeaponDescription("Bolt Caster", "Placeholder")
	end
	
	do --Force Wave
		addWeapon("Force Wave", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			Explosion.ring(x, y, 4, 1, 1, 20, 1, world)
		end, 
		{0.7, 0.7, 1, 1}, nil)
		
		addWeaponDescription("Force Wave", "Placeholder")
	end
	
	do --Hydrocarbon Explosive
		local bulletSpeed = 0
		local simulationBody = Body.newRaw(10, 1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 0
		addWeapon("Hydrocarbon Explosive", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			newBomb(x, y, 10, 1, 0, world, bulletSpeed, angle, Image.letterToImage("O", {0.8, 0, 0, 1}), 0, {0.4, 0, 0, 0.4}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 10, 2, 30, 1000, world)
			end)
		end, 
		{0.8, 0, 0, 1}, simulationBody)
		
		addWeaponDescription("Hydrocarbon Explosive", "Placeholder")
	end
	
	do --Matter Compressor
		local bulletSpeed = 25
		local simulationBody = Body.newRaw(10, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 20
		simulationBody.preciseLanding = true
		
		addWeapon("Matter Compressor", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			local bullet = newBullet(x, y, 10, 1, 0, world, bulletSpeed, angle, Image.letterToImage(">", {0.4, 0.4, 0.4, 1}), 20, {0, 0, 0, 0.8}, function(bullet)
				Explosion.ring(bullet.x, bullet.y, 4, 5, 3, -30, 1, world)
			end)
			local dist = math.sqrt((targetY - y)^2 + (targetX - x)^2)
			bullet.body.duration = (dist - 2)/bulletSpeed
		end, 
		{0.3, 0.3, 0.3, 1}, simulationBody)
		
		addWeaponDescription("Matter Compressor", "Placeholder")
	end
	
	do --Emergency Thruster
		local bulletSpeed = 45
		local bulletDamage = 15
		local minSpeed = 15
		local friction = 4
		local simulationBody = Body.newRaw(bulletDamage, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		simulationBody.friction = friction
		
		addWeapon("Emergency Thruster", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 60, angle + math.pi)
			fireOverSpread(angle, math.pi/5, 13,
			function(a)
				local bullet = newBullet(x, y, bulletDamage, 0.1, 0, world, Random.randomBetweenPoints(bulletSpeed/2, bulletSpeed), a, Image.letterToImage("~", {1, 0.5, 0, 1}), minSpeed, {1, 0.5, 0, 0.4})
				bullet.body.friction = friction
			end)
		end, 
		{1, 0.6, 0.1, 1}, simulationBody)
		
		addWeaponDescription("Emergency Thruster", "Placeholder")
	end

	do --Entropy Orb
		local bulletSpeed = 40
		local bounce = 2
		local bulletDamage = 500
		local bulletMass = 4
		local minSpeed = 5
		local simulationBody = Body.newRaw(bulletDamage, bulletMass, bounce, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		
		addWeapon("Entropy Orb", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			local bullet = newBullet(x, y, bulletDamage, bulletMass, bounce, world, bulletSpeed, angle, Image.letterToImage("o", {0.8, 0, 0.8, 1}), minSpeed, {0.8, 0, 0.8, 0.6})
			bullet.body.speedPerHealth = bulletSpeed/100
		end, 
		{0.8, 0, 0.8, 1}, simulationBody)
		
		addWeaponDescription("Entropy Orb", "Placeholder")
	end
end

do --initialize enemy weapons
	do --Harpy Blaster
		local bulletSpeed = 30
		addWeapon("Harpy Blaster", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			fireOverSpread(angle, math.pi/3, 4,
			function(a)
				newBullet(x, y, 8, 0.1, 0, world, bulletSpeed, a, Image.letterToImage(".", {1, 1, 0, 1}), 15, {0.8, 0.8, 0, 0.8})
			end)
		end, 
		{0, 1, 0, 1}, nil)
	end
	
	do --ChainGun
		local bulletSpeed = 25
		addWeapon("ChainGun", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x) + Random.randomBetweenPoints(-math.pi/6, math.pi/6)
			newBullet(x, y, 12, 0.2, 0, world, bulletSpeed, angle, Image.letterToImage("-", {1, 1, 0, 1}), 15, {1, 1, 0, 0.1})
		end, 
		{0, 1, 0, 1}, nil)
	end
	
	do --Junk Rocket
		local bulletSpeed = 20
		local simulationBody = Body.newRaw(20, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 5
		addWeapon("Junk Rocket", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 10, angle + math.pi)
			newBullet(x, y, 20, 1, 0, world, bulletSpeed, angle, Image.letterToImage(">", {0.5, 0.5, 0.5, 1}), 20, {0.7, 0.3, 0, 0.6}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 4, 1.5, 15, 200, world)
			end)
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
end

function Weapon.simulateFire(weaponName, x, y, targetX, targetY, world)
	local weapon = weapons[weaponName]
	if weapon.bodyTemplate then
		return TrackingLines.new(x, y, targetX, targetY, weapon.bodyTemplate, GlobalTurnTime, {1, 0, 0, 0.4}, world)
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
		
		local xOff, yOff = Misc.angleToOffset(bullet.body.angle, 1)
		TrackingLines.updatePoints(bullet.trackingLine, bullet.body.x, bullet.body.y, bullet.body.x + xOff, bullet.body.y + yOff)
	end
end

function Weapon.drawBullets(bullets, camera)
	for i = 1, #bullets do
		local bullet = bullets[i]
		if bullet.body.tile.visible then
			TileColour.drawColourOnTile({1, 0, 0, 0.2}, bullet.body.tile, camera)
			love.graphics.setColor(1, 1, 1, 1)
			local outline = Misc.oscillateBetween(1, 4, 0.5)
			if globalGame.turnSystem.turnRunning then
				outline = 0
			end
			Image.drawImageWithOutline(bullet.image, camera, bullet.body.x, bullet.body.y, bullet.body.angle, {1, 0, 0, 1}, outline)
		end
	end
end

return Weapon