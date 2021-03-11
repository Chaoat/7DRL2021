local World = {}

function World.new(mapRadius, segmentSize)
	local world = {physicsSystem = PhysicsSystem.new(), map = nil, pathfindingMap = nil, characters = {}, walls = {}, bullets = {}, explosions = {}, trackingLines = {}, enemies = {}, chests = {}, items = {}}
	MapGeneration.generateMapFromStructure(MapGeneration.generateMapStructure(mapRadius), segmentSize, world)
	world.pathfindingMap = Pathfinding.newPathfindingMap(world.map)
	
	Enemy.spawnEnemy("harpy", 0, 0, world)
	Enemy.spawnEnemy("harpy", 1, 0, world)
	Enemy.spawnEnemy("harpy", 1, 1, world)
	Enemy.spawnEnemy("harpy", 1, 2, world)
	Enemy.spawnEnemy("harpy", 0, 1, world)
	Enemy.spawnEnemy("harpy", -1, 0, world)
	
	Chest.new(40, 0, world)
	
	return world
end

function World.draw(world, drawTrackers, camera)
	Map.drawTiles(world.map, camera)
	Wall.drawWalls(world.walls, camera)
	Chest.drawItems(world.items, camera)
	Weapon.drawBullets(world.bullets, camera)
	Explosion.drawExplosions(world.explosions, camera)
	Character.drawCharacters(world.characters, camera)
	
	if drawTrackers then
		TrackingLines.drawAll(world.trackingLines, camera)
	end
	--Body.debugDrawBodies(world.physicsSystem.bodies, game.mainCamera)
	--MapGeneration.testDrawStructure(100, 100, world.map.structure)
end

return World