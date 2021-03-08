local World = {}

function World.new()
	local world = {physicsSystem = PhysicsSystem.new(), map = Map.new(40, 40)}
	Body.new(10, 0, world, 1, 100, 1, "wall")
	
	return world
end

function World.draw(world, camera)
	Map.drawTiles(world.map, camera)
end

return World