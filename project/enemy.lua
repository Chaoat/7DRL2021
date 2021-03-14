local Enemy = {}

function Enemy.new(name, x, y, character, aiFunction)
	--aiFunction(enemy, player)
	
	local world = character.body.world
	local enemy = {name = name, startX = x, startY = y, character = character, aiFunction = aiFunction, alerted = false, firing = false, warned = 0}
	enemy.character.parent = enemy
	table.insert(world.enemies, enemy)
	return enemy
end

local function dodge(enemy, speed)
	local body = enemy.character.body
	local dodgeNeeded = body.inDanger == GlobalTurnNumber
	--print(body.inDanger .. ":" .. GlobalTurnNumber)
	if dodgeNeeded then
		local availableTiles = Vision.getTilesInVision(body.world, body.tile.x, body.tile.y, 1, function(tile)
			return not Tile.checkDangerous(tile)
		end)
		
		if #availableTiles > 0 then
			local target, index = Random.randomFromList(availableTiles)
			local angle = math.atan2(target.y - body.y, target.x - body.x)
			enemy.character.targetX = body.x + speed*math.cos(angle)
			enemy.character.targetY = body.y + speed*math.sin(angle)
			return true
		end
	end
	return false
end

local function pathfindAwayFromPlayer(enemy, player, speed)
	local angle = math.atan2(enemy.character.body.y - player.character.body.y, enemy.character.body.x - player.character.body.x)
	local offX, offY = Misc.angleToDir(angle)
	
	speed = speed + 1
	local eBody = enemy.character.body
	local path = Pathfinding.findPath(enemy.character.body.world.pathfindingMap, {eBody.tile.x, eBody.tile.y}, {Misc.round(eBody.tile.x + speed*offX), Misc.round(eBody.tile.y + speed*offY)}, 1)
	
	if path then
		local targetCoords = path[math.min(speed, #path)]
		enemy.character.targetX = targetCoords[1]
		enemy.character.targetY = targetCoords[2]
	else
		enemy.character.targetX = enemy.character.body.x
		enemy.character.targetY = enemy.character.body.y
	end
end

local function pathfindToPlayer(enemy, player, speed)
	local path = Pathfinding.findPath(enemy.character.body.world.pathfindingMap, {enemy.character.body.tile.x, enemy.character.body.tile.y}, {player.character.body.tile.x, player.character.body.tile.y}, 1)
	if path then
		local targetCoords = path[math.min(speed + 1, #path)]
		enemy.character.targetX = targetCoords[1]
		enemy.character.targetY = targetCoords[2]
	else
		enemy.character.targetX = enemy.character.body.x
		enemy.character.targetY = enemy.character.body.y
	end
end

local enemies = {}
local function newEnemyKind(name, spawnFunc)
	--spawnFunc(x, y, world)
	enemies[name] = {spawnFunc = spawnFunc}
end
do --initEnemies
	do --Harpy
		local flavourText = "Masses of feathers impaled through gaunt flesh, and needle teeth jutting from gnashing jaws define this nightmare creature from The Devourer's dreams. Clutched in its twisted talons  is a rusty hunk of steel barely identifiable as an ancient scatter gun.\n\nThis creature will be easily slain with a bolt or two, but don't let it get too close, for although old, scatterguns still have great flesh tearing capabilities."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				if body.tile.visible then
					local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
					local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
					if dist > 4 or enemy.reloading > 0 then
						if not dodge(enemy, 1) then
							character.targetX = Misc.round(body.x + 2*math.cos(angle))
							character.targetY = Misc.round(body.y + 2*math.sin(angle))
						end
					else
						enemy.firing = true
						TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Harpy Blaster", playerBody.x, playerBody.y, body, body.world), body, 0, turnSystem)
						enemy.reloading = 3
					end
				else
					pathfindToPlayer(enemy, player, 1)
				end
			end
		end
		
		newEnemyKind("Harpy", 
		function(x, y, world)
			local enemy = Enemy.new("Harpy", x, y, Character.new(Body.new(x, y, world, 20, 0.4, 0, "character"), 30, Image.letterToImage("w", {0.1, 0.5, 0.6, 1}), "Harpy", flavourText), aiFunc)
			enemy.character.flying = true
			enemy.character.body.bloody = true
			enemy.reloading = 0
		end)
	end
	
	do --Gremlin
		local flavourText = "These diminutive goblin like creatures are a common sight in your system, peacefully co-inhabiting the planets alongside your people. It took half a Millennia to forgive them for siding with The Devourer in the War of Chains, and it will be a hard fight to rebuild that trust if you can not destroy the weak minded fools before you who have sunk back into evil.\n\nAlways the innovative tinkerer, these Gremlins have managed to scrap together rocket propelled explosives. With what little is available on the station, it is no surprise that these rockets are slow moving and easily dodged. Regardless, the amount of hydrocarbons they've managed to pack into them is frankly impressive, and will most assuredly pack a punch on a direct hit."
		
		local function aiFunc(enemy, player, turnSystem)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				local approach = false
				local run = false
				if not enemy.firing then
					if not dodge(enemy, 1) then
						if body.tile.visible then
							local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
							local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
							
							if dist <= 8 then
								run = true
							elseif dist <= 15 then
								if enemy.reloading == 0 then
									enemy.firing = true
									enemy.weaponDischarge = TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Junk Rocket", playerBody.x, playerBody.y, body, body.world), body, 0.6, turnSystem)
									Sound.singlePlaySound("Shotgun-Reload.wav", 0.4, body.x, body.y)
									enemy.targetX = playerBody.x
									enemy.targetY = playerBody.y
									enemy.targettingLine = Weapon.simulateFire("Junk Rocket", body.x, body.y, playerBody.x, playerBody.y, body.world)
									enemy.targettingLine.creatorBody = body
								end
							end
						else
							approach = true
						end
						
						if approach then
							pathfindToPlayer(enemy, player, 1)
						elseif run then
							pathfindAwayFromPlayer(enemy, player, 1)
						end
					end
				else
					TrackingLines.updatePoints(enemy.targettingLine, body.x, body.y, enemy.targetX, enemy.targetY)
					if enemy.weaponDischarge.fired then
						enemy.firing = false
						enemy.targettingLine.destroy = true
						enemy.reloading = 8
					end
				end
			end
		end
		
		newEnemyKind("Gremlin", 
		function(x, y, world)
			local enemy = Enemy.new("Gremlin", x, y, Character.new(Body.new(x, y, world, 35, 0.8, 0, "character"), 60, Image.letterToImage("g", {0, 0.6, 0.2, 1}), "Gremlin", flavourText), aiFunc)
			enemy.character.body.destroyFunction = function(body)
				if enemy.targettingLine then
					enemy.targettingLine.destroy = true
				end
			end
			enemy.character.body.bloody = true
			enemy.reloading = 0
		end)
	end
	
	do --Saturation Turret
		local name = "Saturation Turret"
		local flavourText = "Your ancestors knew that no matter the strength of their chains, they would never be able to bind The Devourer completely. Although his body is secured, his mind wanders, and twists everything it touches. With this in mind, they constructed the Labyrinth with as mundane materials as they could produce, in hopes they could not be turned to evil. Despite this, The Devourer still managed to twist his prison to his liking, and these turrets are but the first of his designs.\n\nFast firing but inaccurate, try not to stand in their kill zone for too long, lest they land a lucky hit. Other than that, their immobility allows you to dispose of them how and when you desire. Fortunately they also have a limited ammo supply, and have to reload every ten rounds. Use this to your advantage."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				
				if enemy.ammoLeft > 0 then
					enemy.firing = true
					TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("ChainGun", playerBody.x, playerBody.y, body, body.world), body, 0, turnSystem)
				end
				enemy.ammoLeft = enemy.ammoLeft - 1
				
				if enemy.ammoLeft <= -5 then
					enemy.ammoLeft = 10
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 40, 4, 0, "character"), 0, Image.letterToImage("T", {0.7, 0.7, 0, 1}), name, flavourText), aiFunc)
			--Body.anchor(enemy.character.body)
			enemy.ammoLeft = 10
			enemy.character.body.friction = 3
			enemy.character.body.sparky = true
		end)
	end

	do --Missile Battery
		local name = "Missile Battery"
		local flavourText = "Somehow the twisted mass of metal ahead of you manufactures and launches smart rockets capable of tracking your every movement. It is quite the complicated piece of machinery, and if you did not have to obliterate it, the top engineers down planet side would have loved to examine it. Luckily for you, the intricacy of its design should make it easy to disable.\n\nIf left unanswered, the volume of rockets vomited by this foe will easily overwhelm you. Either destroy it with prejudice, or stay out of its sight until you can. Like its brother the Saturation Turret, it also must reload every 10 rounds."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			enemy.reloading = math.max(enemy.reloading - 1, 0)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				local angleToPlayer = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
				local randAngle = angleToPlayer + Random.randomBetweenPoints(-math.pi/4, math.pi/4)
				
				if enemy.ammoLeft <= 0 then
					enemy.ammoLeft = enemy.ammoLeft - 1
					if enemy.ammoLeft <= -6 then
						enemy.ammoLeft = 10
					end
				end
				
				if enemy.reloading <= 0 and enemy.ammoLeft > 0 then
					enemy.firing = true
					TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Battery Missile", body.x + math.cos(randAngle), body.y + math.sin(randAngle), body, body.world), body, 0, turnSystem)
					enemy.ammoLeft = enemy.ammoLeft - 1
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 40, 3, 0, "character"), 0, Image.letterToImage("M", {0.6, 0.6, 0.4, 1}), name, flavourText), aiFunc)
			--Body.anchor(enemy.character.body)
			enemy.character.body.friction = 3
			enemy.reloading = 0
			enemy.ammoLeft = 10
			enemy.character.body.sparky = true
		end)
	end
	
	do --Leaper
		local name = "Leaper"
		local flavourText = "The bloated mass of purple flesh before you is unlike anything you've encountered in all your travels of the nine worlds. Clearly this is some abominable dream of The Devourer's, for nature never could have conceived such a beast. Its only familiar elements are its great muscled legs, reminiscent of the bulltoads of your homeworld. You are fairly certain that its mass alone would be enough to crush you, if it were to charge.\n\nThis foe takes bolts like a brick wall, and will lumber towards you ignoring all explosions and damage until it comes within range. That is not its only offensive power however, as it will violently rupture when slain, damaging all around it. It will also explode when slain, so watch out for that as well. Its only weakness is its slower speed than the majority of the Labyrinth denizens, including yourself."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			enemy.parity = (enemy.parity + 1)%2
			enemy.reloading = enemy.reloading - 1
			
			local body = enemy.character.body
			local playerBody = player.character.body
			
			if enemy.alerted then
				if enemy.targettingLine then
					enemy.targettingLine.destroy = true
				end
				
				local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
				local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
				if dist > 5 or enemy.reloading > 0 or not body.tile.floored then
					if enemy.parity == 1 then
						pathfindToPlayer(enemy, player, 1)
					end
				else
					enemy.firing = true
					TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Leap", playerBody.x, playerBody.y, body, body.world), body, 0.1, turnSystem)
					enemy.targettingLine = Weapon.simulateFire("Leap", body.x, body.y, playerBody.x, playerBody.y, body.world)
					enemy.targettingLine.creatorBody = body
					enemy.reloading = 4
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 150, 10, 0, "character"), 100, Image.letterToImage("L", {0.5, 0, 1, 1}), name, flavourText), aiFunc)
			
			enemy.character.body.destroyFunction = function(body)
				Explosion.colouredExplosion(body.x, body.y, 5, 1.5, 15, 200, world, {0.95, 0.8, 1, 0.7}, {0.4, 0.2, 0.55, 0.3})
				Sound.singlePlaySound("mediumexplosion.wav", 1, x, y)
			end
			enemy.character.body.friction = 5
			enemy.character.body.bloody = true
			enemy.parity = 0
			enemy.reloading = 0
		end)
	end
	
	do --Psiclops
		local name = "Psiclops"
		local flavourText = "This one eyed race is but one of the peoples wiped out with the coming of The Devourer. Such psionic strength has never again been seen in the system since their going, and the legends of your people are filled with stories of the heroic efforts these noble folk went to in defence of good during the War of Chains. It is a testament to their power that The Devourer would choose them, his most hated of enemies, to dream as his defenders, a fact that you would be able to appreciate if you were not so filled with disgust that he would defile their memory by putting them to such a use.\n\nThe power possessed by these fighters is truly awesome, and will easily annihilate you if you are not careful. Luckily for you they can not release their blasts of energy instantaneously, but require some time to concentrate. They are also reluctant to fire when one of their allies would be struck by the blast, a noble trait they retain even in their present condition."
		
		local function aiFunc(enemy, player, turnSystem)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				local approach = false
				local run = false
				if not enemy.firing then
					if not dodge(enemy, 1) then
						if body.tile.visible then
							local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
							local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
							
							if dist <= 6 then
								run = true
							elseif dist <= 15 then
								if enemy.reloading == 0 then
									enemy.firing = true
									enemy.weaponDischarge = TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Power Ball", playerBody.x, playerBody.y, body, body.world), body, 0.8, turnSystem)
									enemy.targettingLine = Weapon.simulateFire("Power Ball", body.x, body.y, playerBody.x, playerBody.y, body.world)
									enemy.targettingLine.creatorBody = body
									Sound.singlePlaySound("laserchargeup.wav", 0.7, body.x, body.y)
								end
							end
						else
							approach = true
						end
						
						if approach then
							pathfindToPlayer(enemy, player, 1)
						elseif run then
							pathfindAwayFromPlayer(enemy, player, 1)
						end
					end
				end
				
				if enemy.firing then
					if enemy.weaponDischarge.fired then
						enemy.firing = false
						enemy.targettingLine.destroy = true
						enemy.reloading = 8
					else
						enemy.weaponDischarge.func = Weapon.prepareWeaponFire("Power Ball", playerBody.x, playerBody.y, body, body.world)
						TrackingLines.updatePoints(enemy.targettingLine, body.x, body.y, playerBody.x, playerBody.y)
						if TrackingLines.totalLength(enemy.targettingLine) <= 7 then
							enemy.firing = false
							enemy.weaponDischarge.cancel = true
							enemy.targettingLine.destroy = true
						end
					end
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 100, 2, 0, "character"), 70, Image.letterToImage("P", {0.5, 0, 0.5, 1}), name, flavourText), aiFunc)
			enemy.character.body.destroyFunction = function(body)
				if enemy.targettingLine then
					enemy.targettingLine.destroy = true
				end
			end
			enemy.character.body.bloody = true
			enemy.reloading = 0
		end)
	end

	do --Wyvern
		local name = "Wyvern"
		local flavourText = "A twisted caricature of the beautiful winged serpents common throughout the system. Just like their terrestrial brethren, these creature use their wings not just as a means of movement, but also as equal parts defensive and offensive weapon. While in flight, their wings create enough force to drive away any slow moving projectiles, and at close range their buffet can break ribs.\n\nAll but immune to your projectiles, you'll have to rely on lucky hits or high explosives to take these ones out. Keep in mind that while their defensive powers are extreme, they are far less deadly than most of the denizens you face."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				if body.tile.visible then
					local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
					local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
					if dist > 4 or enemy.reloading > 0 then
						TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Wing Blast", playerBody.x, playerBody.y, body, body.world), body, 0, turnSystem)
						if not dodge(enemy, 1) then
							character.targetX = Misc.round(body.x + 3*math.cos(angle))
							character.targetY = Misc.round(body.y + 3*math.sin(angle))
						end
					else
						enemy.firing = true
						TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Wing Buffet", playerBody.x, playerBody.y, body, body.world), body, 0.1, turnSystem)
						enemy.reloading = 3
					end
				else
					pathfindToPlayer(enemy, player, 1)
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 80, 5, 0, "character"), 15, Image.letterToImage("W", {0.6, 0.75, 0.75, 1}), name, flavourText), aiFunc)
			enemy.character.flying = true
			enemy.character.body.friction = 0
			enemy.reloading = 0
			enemy.character.body.bloody = true
		end)
	end

	do --Eye of Madness
		local name = "Eye of Madness"
		local flavourText = "The Devourer's dreams are growing stronger, that you can plainly see. It will only be a matter of time before he breaks lose of his bonds, unless of course, you can do something about it. This physical manifestation of The Devourer's body however will do everything in its power to stop you, and unfortunately for you its devastating beams are quite powerful.\n\nHas a lot of staying power, and a powerful instantaneous beam which demands constant movement to dodge. The beam takes a while to charge up however, take advantage of that time. Stay out of its sight while it's charged."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			local body = enemy.character.body
			local playerBody = player.character.body
			
			if enemy.alerted then
				enemy.firing = true
				local beam = TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Eye Blast", playerBody.x, playerBody.y, body, body.world), body, 0.6, turnSystem)
				table.insert(enemy.beams, {beam, playerBody.x, playerBody.y})
			end
			
			if #enemy.beams > 0 then
				local beam = enemy.beams[1]
				if beam[1].triggerTime <= GlobalTurnTime then
					if not enemy.targettingLine then
						enemy.targettingLine = Weapon.simulateFire("Eye Blast", body.x, body.y, beam[2], beam[3], body.world)
						enemy.targettingLine.creatorBody = body
					else
						TrackingLines.updatePoints(enemy.targettingLine, body.x, body.y, beam[2], beam[3])
					end
					table.remove(enemy.beams, 1)
				end
			elseif enemy.targettingLine then
				enemy.targettingLine.destroy = true
				enemy.targettingLine = false
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 100, 10, 0, "character"), 0, Image.letterToImage("E", {0.9, 0, 0, 1}), name, flavourText), aiFunc)
			--Body.anchor(enemy.character.body)
			enemy.character.body.friction = 10
			enemy.beams = {}
			enemy.character.body.bloody = true
		end)
	end

	do --Caretaker
		local name = "Caretaker"
		local flavourText = "After a millenium of imprisonment, it is little surprise that The Devourer has come to see his prison as his home, having known nothing else for all that time. This strange mechanical spider is evidence of that, as it carefully lays its carelings around the station to skitter off and repair the damage you've dealt to it. Despite its benign intentions however, it is still a minion of The Devourer, and will fight against you in whatever way it can.\n\nThis foe spawns an endless stream of Carelings, little creatures that charge towards you and self detonate, leaving a wall in their place. This might not seem like that much of a threat, but too many walls building up can really clog up your firing lines, and no one likes spending ammunition clearing blockages."
		
		local function aiFunc(enemy, player, turnSystem)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				local approach = false
				local run = false
				if not dodge(enemy, 6) then
					if body.tile.visible then
						local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
						local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
						
						if dist < 12 then
							run = true
						elseif dist > 14 then
							approach = true
						end
					else
						approach = true
					end
					
					if approach then
						pathfindToPlayer(enemy, player, 1)
					elseif run then
						pathfindAwayFromPlayer(enemy, player, 1)
					end
				end
				
				firing = false
				if enemy.reloading == 0 then
					local angle = Random.randomBetweenPoints(0, 2*math.pi)
					firing = true
					TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("SpawnScrew", body.x + math.cos(angle), body.y + math.sin(angle), body, body.world), body, 0, turnSystem)
					enemy.reloading = 4
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 65, 5, 0, "character"), 500, Image.letterToImage("C", {0, 1, 1, 1}), name, flavourText), aiFunc)
			enemy.reloading = 0
			enemy.character.body.sparky = true
		end)
	end
	
	do --Careling
		local name = "Careling"
		local flavourText = "Spawn of the Caretaker, beware its forceful blast."
		
		local function aiFunc(enemy, player, turnSystem)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				local approach = true
				local run = false
				if not dodge(enemy, 6) then
					if body.tile.visible then
						local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
						local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
						
						if dist <= 3 then
							Body.destroy(body)
						end
					end
					
					if approach then
						pathfindToPlayer(enemy, player, 1)
					elseif run then
						pathfindAwayFromPlayer(enemy, player, 1)
					end
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 20, 0.8, 0, "character"), 80, Image.letterToImage("c", {0, 1, 1, 1}), name, flavourText), aiFunc)
			enemy.reloading = 0
			
			enemy.character.body.sparky = true
			enemy.character.body.destroyFunction = function(body)
				Explosion.ring(body.x, body.y, 1, 2, 0.5, 10, 0, world)
				Sound.singlePlaySound("energywave.wav", 0.2, body.x, body.y)
				if not body.tile.floored then
					Tile.reFloor(body.tile, 100)
				else
					Wall.new(world, body.tile.x, body.tile.y)
				end
			end
			
			return enemy
		end)
	end
	
	do --Wiyht
		local name = "Wiyht"
		local flavourText = "These beings were supposedly wiped out during the War of Chains, living on only in the nightmares of children. There have always been rumours though that they survived, lurking in the deep darkness of the furthest reaches of the system. Many are the drunken ramblings of old pilots venturing out too far and witnessing the ancient horrors that dwell on the furthest asteroids. Most of these can be explained by madness bred from isolation in the infinite darkness of space, however it seems that they held a grain of truth, for how else could these allies of The Devourer have survived through the last millennium.\n\nWiyhts are incredible powerful psionics, sharing a portion of The Devourer's reality shaping powers. Whenever they are in range, they will violently morph nearby walls into powerful Golems, that though slow, pack a punch with their heavy fists. Don't bother too much with the Golems, they will eat your ammunition like a black hole, but the Wiyhts are priority number one targets."
		
		local function aiFunc(enemy, player, turnSystem)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				firing = false
				
				local approach = false
				local run = false
				if not dodge(enemy, 2) then
					if enemy.reloading > 0 then
						run = true
					else
						local appropriateTiles = Vision.getTilesInVision(body.world, body.x, body.y, 10, function(tile)
						local playerDist = math.sqrt((tile.x - playerBody.x)^2 + (tile.y - playerBody.y)^2)
						return #tile.bodies["wall"] > 0 and playerDist <= 5
						end)
						
						if #appropriateTiles > 0 then
							local tile = Random.randomFromList(appropriateTiles)
							firing = true
							
							Body.destroy(tile.bodies["wall"][1])
							TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("SpawnGolem", tile.x, tile.y, body, body.world), body, 0, turnSystem)
							enemy.targettingLine = TrackingLines.newSinglePointTracker(tile.x, tile.y, {1, 0.7, 0.8, 1}, body)
							enemy.targettingLine.creatorBody = body
							enemy.reloading = 10
						else
							approach = true
						end
					end
				end
				
				if not firing and enemy.targettingLine then
					enemy.targettingLine.destroy = true
				end
				
				if approach then
					pathfindToPlayer(enemy, player, 1)
				elseif run then
					pathfindAwayFromPlayer(enemy, player, 1)
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 120, 5, 0, "character"), 80, Image.letterToImage("Y", {0.8, 0.8, 0.6, 1}), name, flavourText), aiFunc)
			enemy.reloading = 0
			enemy.character.body.bloody = true
		end)
	end
	
	do --Golem
		local name = "Golem"
		local flavourText = "A hulking mass of metal animated by a Wiyht. Very slow, but be careful of its deadly fists when it does get close."
		
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			enemy.parity = (enemy.parity + 1)%3
			enemy.reloading = math.max(enemy.reloading - 1, 0)
			
			local body = enemy.character.body
			local playerBody = player.character.body
			
			if enemy.alerted then
				if enemy.targettingLine then
					enemy.targettingLine.destroy = true
				end
				
				local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
				local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
				
				if enemy.parity == 1 then
					pathfindToPlayer(enemy, player, 1)
				end
				if dist < 3 and enemy.reloading == 0 then
					enemy.firing = true
					TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Golem Fist", playerBody.x, playerBody.y, body, body.world), body, 0.1, turnSystem)
					enemy.reloading = 2
				end
			end
		end
		
		newEnemyKind(name, 
		function(x, y, world)
			local enemy = Enemy.new(name, x, y, Character.new(Body.new(x, y, world, 180, 15, 0, "character"), 100, Image.letterToImage("G", {0.5, 0.5, 0.5, 1}), name, flavourText), aiFunc)
			
			enemy.character.body.friction = 10
			enemy.parity = 0
			enemy.reloading = 0
			enemy.character.body.sparky = true
			return enemy
		end)
	end
end

local warnLimit = 9
function Enemy.warnEnemy(enemy, amount)
	if not enemy.alerted then
		enemy.warned = math.min(enemy.warned + amount, warnLimit)
		if enemy.warned >= warnLimit then
			enemy.alerted = true
			Enemy.shout(enemy.character.body, 4, 3)
		end
	end
end

function Enemy.shout(body, range, volume)
	local tiles = Vision.getTilesInVision(body.world, body.x, body.y, range, function(tile)
		return #tile.bodies["character"] > 0
	end)
	
	for i = 1, #tiles do
		local tile = tiles[i]
		local body = tile.bodies["character"][1]
		if body.parent.parent then
			Enemy.warnEnemy(body.parent.parent, volume)
		end
	end
end

function Enemy.decideActions(enemies, player, turnSystem)
	for i = 1, #enemies do
		local enemy = enemies[i]
		if not enemy.character.body.destroy and enemy.aiFunction and not player.spaced then
			if not enemy.character.body.tile.visible then
				enemy.warned = math.max(enemy.warned - 0.5, 0)
				if enemy.warned == 0 then
					enemy.alerted = false
				end
			else
				Enemy.warnEnemy(enemy, 1)
			end
			
			enemy.aiFunction(enemy, player, turnSystem)
		end
	end
end

function Enemy.spawnEnemy(name, x, y, world)
	return enemies[name].spawnFunc(x, y, world)
end

return Enemy