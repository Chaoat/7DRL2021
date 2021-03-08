local Wall = {}

function Wall.new(world, x, y)
	local wall = {body = Body.new(x, y, world, 1, 1000, 1, "wall")}
	wall.body.friction = 1
	return wall
end

return Wall