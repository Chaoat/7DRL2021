local Enemy = {}

function Enemy.new(name, x, y, character, aiFunction)
	--aiFunction(enemy, player)
	
	local world = character.body.world
	local enemy = {name = name, startX = x, startY = y, character = character, aiFunction = aiFunction, alerted = true, firing = false}
	table.insert(world.enemies, enemy)
	return enemy
end

local function pathfindToPlayer(enemy, player, speed)
	local path = Pathfinding.findPath(enemy.character.body.world.pathfindingMap, {enemy.character.body.tile.x, enemy.character.body.tile.y}, {player.character.body.tile.x, player.character.body.tile.y}, 1)
	local targetCoords = path[math.min(speed + 1, #path)]
	return targetCoords
end

local enemies = {}
local function newEnemyKind(name, spawnFunc)
	--spawnFunc(x, y, world)
	enemies[name] = {spawnFunc = spawnFunc}
end
do --initEnemies
	do --harpy
		local function aiFunc(enemy, player, turnSystem)
			if enemy.alerted then
				local body = enemy.character.body
				local playerBody = player.character.body
				local character = enemy.character
				
				enemy.reloading = math.max(enemy.reloading - 1, 0)
				
				if body.tile.visible then
					local angle = math.atan2(playerBody.y - body.y, playerBody.x - body.x)
					local dist = math.sqrt((playerBody.y - body.y)^2 + (playerBody.x - body.x)^2)
					if dist > 4 or enemy.reloading > 0 then
						character.targetX = Misc.round(body.x + 2*math.cos(angle))
						character.targetY = Misc.round(body.y + 2*math.sin(angle))
					else
						enemy.firing = true
						TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire("Harpy Blaster", body.x, body.y, playerBody.x, playerBody.y, body, body.world), 0, turnSystem)
						enemy.reloading = 3
					end
				else
					local targetCoords = pathfindToPlayer(enemy, player, 1)
					character.targetX = targetCoords[1]
					character.targetY = targetCoords[2]
				end
			end
		end
		
		newEnemyKind("harpy", 
		function(x, y, world)
			local enemy = Enemy.new("harpy", x, y, Character.new(Body.new(x, y, world, 20, 0.4, 0, "character"), 30, Image.letterToImage("w", {0, 0.8, 0, 1})), aiFunc)
			enemy.character.flying = true
			enemy.reloading = 0
		end)
	end
end

function Enemy.decideActions(enemies, player, turnSystem)
	for i = 1, #enemies do
		local enemy = enemies[i]
		if not enemy.character.body.destroy and enemy.aiFunction then
			enemy.aiFunction(enemy, player, turnSystem)
		end
	end
end

function Enemy.spawnEnemy(name, x, y, world)
	return enemies[name].spawnFunc(x, y, world)
end

return Enemy