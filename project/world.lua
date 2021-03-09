local World = {}

function World.new(mapRadius, segmentSize)
	local world = {physicsSystem = PhysicsSystem.new(), map = nil, characters = {}, bullets = {}}
	MapGeneration.generateMapFromStructure(MapGeneration.generateMapStructure(mapRadius), segmentSize, world)
	
	return world
end

function World.draw(world, camera)
	Map.drawTiles(world.map, camera)
	
	MapGeneration.testDrawStructure(100, 100, world.map.structure)
end

return World