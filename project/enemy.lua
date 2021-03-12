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
	local dodgeNeeded = Tile.checkDangerous(body.tile)
	if dodgeNeeded then
		local availableTiles = Vision.getTilesInVision(body.world, body.tile.x, body.tile.y, speed, function(tile)
			return not Tile.checkDangerous(tile)
		end)
		
		if #availableTiles > 0 then
			local target = Random.randomFromList(availableTiles)
			enemy.character.targetX = target.x
			enemy.character.targetY = target.y
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
	print(path)
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
			local enemy = Enemy.new("Harpy", x, y, Character.new(Body.new(x, y, world, 20, 0.4, 0, "character"), 30, Image.letterToImage("w", {0, 0.8, 0, 1})), aiFunc)
			enemy.character.flying = true
			enemy.reloading = 0
		end)
	end
	
	do --Gremlin
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
			local enemy = Enemy.new("Gremlin", x, y, Character.new(Body.new(x, y, world, 35, 0.8, 0, "character"), 60, Image.letterToImage("g", {0, 0.6, 0.2, 1})), aiFunc)
			enemy.character.body.destroyFunction = function(body)
				if enemy.targettingLine then
					enemy.targettingLine.destroy = true
				end
			end
			enemy.reloading = 0
		end)
	end
	
	do --Saturation Turret
		local function aiFunc(enemy, player, turnSystem)
			enemy.firing = false
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				
				--if body.tile.visible then
					enemy.firing = true
					TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("ChainGun", playerBody.x, playerBody.y, body, body.world), body, 0, turnSystem)
				--end
			end
		end
		
		newEnemyKind("Saturation Turret", 
		function(x, y, world)
			local enemy = Enemy.new("Saturation Turret", x, y, Character.new(Body.new(x, y, world, 50, 4, 0, "character"), 0, Image.letterToImage("T", {0.7, 0.7, 0, 1})), aiFunc)
			--Body.anchor(enemy.character.body)
			enemy.character.body.friction = 3
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
		if not enemy.character.body.destroy and enemy.aiFunction then
			if not enemy.character.body.tile.visible then
				enemy.warned = math.max(enemy.warned - 1, 0)
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