local World = {}

function World.new()
	local world = {physicsSystem = PhysicsSystem.new(), map = Map.new(40, 40), characters = {}}
	Wall.new(world, 10, 0)
	Wall.new(world, 10, 1)
	Wall.new(world, 10, 2)
	Wall.new(world, 10, 3)
	Wall.new(world, 10, 4)
	
	return world
end

function World.draw(world, camera)
	Map.drawTiles(world.map, camera)
end

return World