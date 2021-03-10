local World = {}

function World.new(mapRadius, segmentSize)
	local world = {physicsSystem = PhysicsSystem.new(), map = nil, characters = {}, walls = {}, bullets = {}, explosions = {}, trackingLines = {}, enemies = {}}
	MapGeneration.generateMapFromStructure(MapGeneration.generateMapStructure(mapRadius), segmentSize, world)
	
	Enemy.spawnEnemy("harpy", 30, 0, world)
	Enemy.spawnEnemy("harpy", 31, 0, world)
	Enemy.spawnEnemy("harpy", 31, 1, world)
	Enemy.spawnEnemy("harpy", 31, 2, world)
	Enemy.spawnEnemy("harpy", 30, 1, world)
	Enemy.spawnEnemy("harpy", 29, 0, world)
	
	return world
end

function World.draw(world, drawTrackers, camera)
	Map.drawTiles(world.map, camera)
	Wall.drawWalls(world.walls, camera)
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