local World = {}

function World.new(mapRadius, segmentSize)
	local world = {physicsSystem = PhysicsSystem.new(), map = nil, pathfindingMap = nil, characters = {}, walls = {}, bullets = {}, explosions = {}, trackingLines = {}, enemies = {}, chests = {}, items = {}, endOrbs = {}, shields = {}, particles = {}, itemLevel = 1}
	MapGeneration.generateMapFromStructure(MapGeneration.generateMapStructure(mapRadius), segmentSize, world)
	
	MapGeneration.populateEnemies(world.map.structure, world)
	world.pathfindingMap = Pathfinding.newPathfindingMap(world.map)
	
	return world
end

function World.draw(world, drawTrackers, camera)
	Tile.drawCanvas(world.map, camera)
	Map.drawTiles(world.map, camera)
	Wall.drawWalls(world.walls, camera)
	Particle.drawAll(world.particles, camera)
	Chest.drawItems(world.items, camera)
	Shield.drawShields(world.shields, camera)
	Weapon.drawBullets(world.bullets, camera)
	Explosion.drawExplosions(world.explosions, camera)
	Character.drawCharacters(world.characters, camera)
	
	if drawTrackers then
		TrackingLines.drawAll(world.trackingLines, camera)
	end
	--Body.debugDrawBodies(world.physicsSystem.bodies, camera)
	--MapGeneration.testDrawStructure(100, 100, world.map.structure)
end

return World