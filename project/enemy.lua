local Enemy = {}

function Enemy.new(x, y, character)
	local world = character.body.world
	local enemy = {startX = x, startY = y, character = character}
	table.insert(world.enemies, enemy)
	return enemy
end

local enemies = {}
local function newEnemyKind(name, spawnFunc)
	--spawnFunc(x, y, world)
	enemies[name] = {spawnFunc = spawnFunc}
end
do --initEnemies
	do --harpy
		newEnemyKind("harpy", 
		function(x, y, world)
			Enemy.new(x, y, Character.new(Body.new(x, y, world, 30, 1, 0, "character"), 50, Image.letterToImage("w", {0, 0.8, 0, 1})))
		end)
	end
end

function Enemy.decideActions()
	
end

function Enemy.spawnEnemy(name, x, y, world)
	return enemies[name].spawnFunc(x, y, world)
end

return Enemy