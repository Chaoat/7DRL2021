local World = {}

function World.new(mapRadius, segmentSize)
	local world = {physicsSystem = PhysicsSystem.new(), map = nil, characters = {}, walls = {}, bullets = {}, explosions = {}, trackingLines = {}}
	MapGeneration.generateMapFromStructure(MapGeneration.generateMapStructure(mapRadius), segmentSize, world)
	
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