local Weapon = {}

local function newDeadly(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, layer, loopSound)
	local xOff, yOff = Misc.angleToOffset(angle, 1)
	--print(x + xOff .. " : " .. y + yOff .. " : " .. angle/math.pi)
	local tile = Map.getTile(world.map, x + xOff, y + yOff)
	if Tile.checkBlocking(tile, layer) then
		xOff = 0
		yOff = 0
	end
	
	local body = Body.new(x + xOff, y + yOff, world, health, mass, bounce, layer)
	body.speedPerHealth = 1
	body.speedThreshold = 0
	local bullet = {body = body, image = image, trailColour = trailColour, loopSound = loopSound}
	Body.impartForce(body, speed*mass, angle)
	body.minSpeed = minSpeed
	
	bullet.trackingLine = TrackingLines.new(body.x, body.y, body.x + xOff, body.y + yOff, body, GlobalTurnTime, {1, 0, 0, 0.4}, world)
	
	if body.tile == nil then
		error("what")
	end
	
	body.destroyFunction = destroyFunction
	
	table.insert(world.bullets, bullet)
	return bullet
end

local function newBullet(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, loopSound)
	return newDeadly(x, y, health, mass, bounce, world, speed, angle, image, minSpeed, trailColour, destroyFunction, "bullet", loopSound)
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
		local simulationBody = Body.newRaw(8, 0.1, 0, "bullet")
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
				Sound.singlePlaySound("SmallExplosion.mp3", 0.1, bullet.x, bullet.y)
			end)
			Sound.singlePlaySound("HeavyLaserShot.wav", 0.1, x, y)
		end, 
		{0, 1, 0, 1}, simulationBody)
		
		addWeaponDescription("Bolt Caster", "Weapons such as these have been in use by your people since the War of Chains. A simple acceleration drive loaded with unstable kyroxin rods delivers lethal firepower at a reasonable distance. The Devourer will be all to pleased to see his old nemesis again.\n\nSimple point and shoot. Too short a range and the bolt's explosion will damage you as well, too long a range and your target might dodge before your projectile reaches them. At medium distances however it's just right. Be careful firing this one too fast though, the explosive nature of the ammunition can on occasion cause a chain reaction, detonating bolts in mid flight all the way back to the source. ")
	end
	
	do --Force Wave
		addWeapon("Force Wave", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			Explosion.ring(x, y, 4, 1, 0.7, 20, 1, world)
			Sound.singlePlaySound("energywave.wav", 0.4, x, y)
		end, 
		{0.7, 0.7, 1, 1}, nil)
		
		addWeaponDescription("Force Wave", "The second part of the traditional duelling gear used by your people. It takes many years of practice to become fast enough to deflect bolts out of the air, but once you know how, no projectile can touch you. Only through surprise can such a one be slain with a bolt caster, surprise which the true masters of the Force Wave gladly employ, for what is more surprising than ones own weapon being reflected back in their face.\n\nA powerful defensive tool, but do not disregard the offensive power it contains. All but the fastest projectiles can be reflected, and just the force of the blast alone is enough to splatter smaller enemies against walls.")
	end
	
	do --Hydrocarbon Explosive
		local simulationBody = Body.newRaw(10, 1, 0, "bullet")
		simulationBody.speed = 1
		simulationBody.minSpeed = 0
		addWeapon("Hydrocarbon Explosive", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			newBomb(x, y, 10, 1, 0, world, 0, angle, Image.letterToImage("O", {0.8, 0, 0, 1}), 0, {0.4, 0, 0, 0.4}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 10, 2, 30, 1000, world)
				Sound.singlePlaySound("bigexplosion.wav", 0.8, x, y)
			end)
			Sound.singlePlaySound("barrel.ogg", 0.4, x, y)
		end, 
		{0.8, 0, 0, 1}, simulationBody)
		
		addWeaponDescription("Hydrocarbon Explosive", "On the one hand, what you have before you can hardly be called a weapon, more like useless fuel for war machines that you sorely wish you had. On the other hand, what could be more of a weapon than a barrel filled with a random mishmash of petrochemicals guaranteed to level everything in a ten meter radius. You wonder what possessed the techs to waste space in the cargo pods with this, but you're in no position to requisition anything better.\n\nEXPLOSION IS VERY LARGE, DETONATE FROM A SAFE DISTANCE.\nStrong enough to blow open walls, and can kill anything at close enough range. Only downside is that it can't be launched, only placed. If you have the time, pushing it is enough to send it flying in the low friction environment of the Labyrinth, but this is not recommended when in the thick of combat.")
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
				Sound.singlePlaySound("implosion.ogg", 0.3, x, y)
			end, Sound.loopPlayerSound("jetpackloop.ogg", 0.2, x, y))
			Sound.singlePlaySound("mediumexplosion.wav", 0.1, x, y)
			local dist = math.sqrt((targetY - y)^2 + (targetX - x)^2)
			bullet.body.duration = (dist - 2)/bulletSpeed
		end, 
		{0.3, 0.3, 0.3, 1}, simulationBody)
		
		addWeaponDescription("Matter Compressor", "Now these are the advanced weapons you've been waiting for. Fires a warhead loaded with an unstable gravity matrix that will collapse on detonation, violently yanking everything in the vicinity towards it. For weak enemies, the gravitational forces thus encountered will be enough to tear them limb from limb. For strong enemies, the flying limbs of weak enemies should be enough to take them out.\n\nVery powerful in general use, extraordinarily powerful when used on groups. Comes with an intelligent warhead for pinpoint detonation, guaranteed to explode at precisely the location selected. Don't underestimate the force of this weapon, not even the Labyrinth walls will be able to stand against it.")
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
			Sound.singlePlaySound("shotgun.wav", 0.5, x, y)
		end, 
		{1, 0.6, 0.1, 1}, simulationBody)
		
		addWeaponDescription("Emergency Thruster", "The thruster jet of a small spacecraft, miniaturised down and with a one use fuel source built in. You thought they'd scrapped these after the last unfortunate splattering of a forgetful warrior who neglected to check his back for walls. You guess they had to send all that surplus somewhere though, and if there was any environment where they'd come in handy, it's this.\n\nJust point it at danger and pull the trigger, and you'll be safe in seconds. That is of course if you don't have a wall, or more danger behind you. Regardless, careful use of this device can pull you out of even the most deadly situations.")
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
			bullet.body.speedPerHealth = bulletSpeed/50
			Body.setBounceSound(bullet.body, "energybounce.wav", 0.1)
			Sound.singlePlaySound("energybounce.wav", 0.4, x, y)
		end, 
		{0.8, 0, 0.8, 1}, simulationBody)
		
		addWeaponDescription("Entropy Orb", "How the weapons engineers managed to get an energy source small enough to fuel this engine of destruction, you'll never know. The only time you've ever seen one of these fired was from the deck of a fusion powered warship, and even then the lights went out on every volley. Nevertheless, this bouncy ball of death will surely tear up dream demons just as well as it tears up pirate frigates.\n\nWhen used against a single enemy, this weapon guarantees death. When used against many enemies, this weapon can make no promises, but it will likely be a slaughter. The bouncing motion of the ball can be difficult to predict, but wherever it strikes someone will fall. Just make sure that someone isn't you.")
	end

	do --Sanctuary Sphere
		local bulletSpeed = 20
		local simulationBody = Body.newRaw(10, 0.5, 2, "bullet")
		simulationBody.speedThreshold = 100
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = 0
		simulationBody.preciseLanding = true
		
		addWeapon("Sanctuary Sphere", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			local bullet = newBullet(x, y, 10, 0.5, 2, world, bulletSpeed, angle, Image.letterToImage("+", {0, 1, 1, 1}), 0, {0, 1, 1, 0.5}, function(bullet)
				Shield.new(bullet.x, bullet.y, 3, world)
				Sound.singlePlaySound("plasmagun_medium.wav", 0.2, x, y)
			end)
			Sound.singlePlaySound("whoosh.wav", 0.3, x, y)
			local dist = math.sqrt((targetY - y)^2 + (targetX - x)^2)
			bullet.body.duration = math.max((dist - 2)/bulletSpeed, 0)
			bullet.body.speedThreshold = 100
		end, 
		{0, 1, 1, 1}, simulationBody)
		
		addWeaponDescription("Sanctuary Sphere", "A truly remarkable feat of engineering, the force projected from this device is removed from time, but not space. It's lack of temporal association makes it theoretically invulnerable, and has a side effect of reflecting any projectile striking it. This makes it perfect for use in a defensive shield, as it is capable of reflecting even explosions.\n\nA powerful defensive device, as long as you sit inside the radius, nothing from outside can harm you. The shield lasts forever, whether you consider that a positive or a negative, so be careful where you place it lest it end up protecting your enemies more than you. It can be deployed at a distance, or directly on top of you.")
	end

	do --Annihilator Cannon
		local bulletSpeed = 80
		local bulletHealth = 150
		local speedToHealth = 0.5
		local simulationBody = Body.newRaw(bulletHealth, 0.1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.speedPerHealth = speedToHealth
		simulationBody.minSpeed = 20
		addWeapon("Annihilator Cannon", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 35, angle + math.pi)
			local bullet = newBullet(x, y, bulletHealth, 2, 0, world, bulletSpeed, angle, Image.letterToImage("-", {0.9, 0.8, 0.6, 1}), 20, {0.9, 0.8, 0.6, 0.3}, function(bullet)
				Explosion.targettedExplosion(bullet.x, bullet.y, 15, bullet.angle, math.pi/2, 0.5, 20, 1000, world)
				Sound.singlePlaySound("EnergyExplosion.wav", 0.4, x, y)
			end)
			bullet.body.speedPerHealth = speedToHealth
			Sound.singlePlaySound("AnnihilatorCannonShot.wav", 0.5, x, y)
		end, 
		{0.9, 0.8, 0.6, 1}, simulationBody)
		
		addWeaponDescription("Annihilator Cannon", "During the War of Chains, a need was found for a weapon capable of melting ultra reinforced steel from kilometres away. To satisfy this need, the Annihilator shell was produced, packed with high explosives fitted in a cone warhead to focus the blast on the armour being penetrated. Launched from a 50 metre barrel, this munition was capable of obliterating any and all obstruction that lay between it and its target. After hearing about the foes faced by the last runner, the techs thought you might need some of these.\n\nThe ultimate in destructive power, anything you point this at will die, if you can get the warhead to go off that is. Designed for penetrating walls, these shells will tear straight through a weak target, and bounce off a strong one on anything but a direct hit. Coupled with the shoulder wrenching recoil, this weapon is finicky at best, but decisive if used correctly.")
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
			Sound.singlePlaySound("shotgun.wav", 0.2, x, y)
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
			Sound.singlePlaySound("smgsingleshot.wav", 0.2, x, y)
		end, 
		{0, 1, 0, 1}, nil)
	end
	
	do --Junk Rocket
		local bulletSpeed = 20
		local minSpeed = 5
		local simulationBody = Body.newRaw(20, 1, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		addWeapon("Junk Rocket", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 10, angle + math.pi)
			newBullet(x, y, 20, 1, 0, world, bulletSpeed, angle, Image.letterToImage(">", {0.5, 0.5, 0.5, 1}), minSpeed, {0.7, 0.3, 0, 0.6}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 4, 1.5, 15, 200, world)
				Sound.singlePlaySound("mediumexplosion2.wav", 0.4, bullet.x, bullet.y)
			end, Sound.loopPlayerSound("jetpackloop.ogg", 0.4, x, y))
			Sound.singlePlaySound("mediumexplosion.wav", 0.2, x, y)
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
	
	do --Battery Missile
		local bulletSpeed = 10
		local damage = 10
		local mass = 0.5
		local minSpeed = 0
		local simulationBody = Body.newRaw(damage, mass, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		addWeapon("Battery Missile", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			local bullet = newBullet(x, y, damage, mass, 0, world, bulletSpeed, angle, Image.letterToImage("=", {0.5, 0.5, 0, 1}), minSpeed, {0.7, 0, 0, 0.3}, function(bullet)
				Explosion.explode(bullet.x, bullet.y, 1, 1, 15, 70, world)
				Sound.singlePlaySound("mediumexplosion2.wav", 0.3, bullet.x, bullet.y)
			end, Sound.loopPlayerSound("jetpackloop.ogg", 0.2, x, y))
			Sound.singlePlaySound("missile.wav", 0.3, x, y)
			bullet.body.duration = 3
			bullet.body.speedThreshold = 5
			Body.setTracking(bullet.body, globalGame.player.character.body, 10, 30)
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
	
	do --Leap
		local bulletSpeed = 40
		local damage = 150
		local mass = 10
		local minSpeed = 15
		local simulationBody = Body.newRaw(damage, mass, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		addWeapon("Leap", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, bulletSpeed*firingBody.mass, angle)
			Sound.singlePlaySound("heavyFootstep.ogg", 0.6, x, y)
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
	
	do --Power Ball
		local bulletSpeed = 50
		local damage = 50
		local mass = 1
		local minSpeed = 30
		local simulationBody = Body.newRaw(damage, mass, 0, "bullet")
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		addWeapon("Power Ball", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			local bullet = newBullet(x, y, damage, mass, 0, world, bulletSpeed, angle, Image.letterToImage("*", {1, 0, 1, 1}), minSpeed, {1, 0, 1, 0.7}, function(bullet)
				Explosion.colouredExplosion(bullet.x, bullet.y, 8, 5, 40, 500, world, {1, 0.5, 1, 0.7}, {1, 0, 1, 0.3})
				Sound.singlePlaySound("EnergyExplosion.wav", 0.3, x, y)
			end, Sound.loopPlayerSound("psiPass.ogg", 0.6, x, y))
			Sound.singlePlaySound("psiBlast.ogg", 0.6, x, y)
			bullet.body.speedPerHealth = 0.01
		end, 
		{0, 1, 0, 1}, simulationBody)
	end
	
	do --Wing Buffet
		local bulletSpeed = 30
		addWeapon("Wing Buffet", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Body.impartForce(firingBody, 40, angle + math.pi)
			Explosion.targettedBlast(x, y, 6, angle, math.pi/4, 0.5, 20, 10, world)
			Sound.singlePlaySound("flap.ogg", 0.5, x, y)
		end, 
		{0, 1, 0, 1}, nil)
	end
	
	do --Wing Blast
		addWeapon("Wing Blast", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			Explosion.ring(x, y, 2, 1, 0.05, 40, 0, world)
			Sound.singlePlaySound("flap.ogg", 0.2, x, y)
		end, 
		{0.7, 0.7, 1, 1}, nil)
		
	end
	
	do --Eye Blast
		local bulletSpeed = 100
		local damage = 20
		local mass = 0.1
		local minSpeed = 0
		local simulationBody = Body.newRaw(damage, mass, 0, "bullet")
		simulationBody.speedPerHealth = 0.01
		simulationBody.speed = bulletSpeed
		simulationBody.minSpeed = minSpeed
		addWeapon("Eye Blast", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			local bullet = newBullet(x, y, damage, mass, 0, world, bulletSpeed, angle, Image.letterToImage(" ", {1, 0, 0, 1}), minSpeed, {1, 0.4, 0.4, 1})
			bullet.body.speedPerHealth = 0.01
			Sound.singlePlaySound("eyeblast.ogg", 0.3, x, y)
		end, 
		{0.7, 0.7, 1, 1}, simulationBody)
	end

	do --SpawnScrew
		addWeapon("SpawnScrew", 
		function(targetX, targetY, firingBody, world)
			local enemy = Enemy.spawnEnemy("Careling", targetX, targetY, world)
			Enemy.warnEnemy(enemy, 9)
			Sound.singlePlaySound("turretdeath1.wav", 0.2, targetX, targetY)
		end, 
		{0, 1, 0, 1}, nil)
	end
	
	do --SpawnGolem
		addWeapon("SpawnGolem", 
		function(targetX, targetY, firingBody, world)
			Explosion.ring(targetX, targetY, 2, 1, 1, 40, 10, world)
			--Explosion.colouredExplosion(targetX, targetY, 2, 1, 40, 10, world, {0.9, 0.9, 1, 0.8}, {0.4, 0.4, 0.5, 0.4})
			local enemy = Enemy.spawnEnemy("Golem", targetX, targetY, world)
			Enemy.warnEnemy(enemy, 9)
			Sound.singlePlaySound("transform.ogg", 1, targetX, targetY)
		end, 
		{0, 1, 0, 1}, nil)
	end
	
	do --Golem Fist
		local bulletSpeed = 30
		addWeapon("Golem Fist", 
		function(targetX, targetY, firingBody, world)
			local x = firingBody.x
			local y = firingBody.y
			local angle = math.atan2(targetY - y, targetX - x)
			Explosion.targettedBlast(x, y, 4, angle, math.pi/6, 0.4, 10, 15, world)
			Sound.singlePlaySound("heavyFootstep.ogg", 0.8, targetX, targetY)
		end, 
		{0, 1, 0, 1}, nil)
	end
end

function Weapon.clearDeadly(deadlies, map)
	local i = #deadlies
	while i > 0 do
		local deadly = deadlies[i]
		if not deadly.permanent then
			local body = deadly.body
			
			if deadly.loopSound then
				deadly.loopSound[1]:stop()
				deadly.loopSound[1]:release()
			end
			
			body.destroy = true
			Map.addTileToCleanQueue(body.map, body.tile, body.layer)
			deadly.trackingLine.destroy = true
			table.remove(deadlies, i)
		end
		i = i - 1
	end
	
	Map.cleanAllTiles(map)
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
		
		local distFromCenter = math.sqrt(bullet.body.x^2 + bullet.body.y^2)
		
		if bullet.loopSound then
			Sound.updateVolume(bullet.loopSound, bullet.body.x, bullet.body.y)
		end
		
		if bullet.body.destroy or distFromCenter >= 75 then
			if bullet.loopSound then
				bullet.loopSound[1]:stop()
				bullet.loopSound[1]:release()
			end
			Body.destroy(bullet.body)
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