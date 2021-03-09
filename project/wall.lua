local Wall = {}

function Wall.new(world, x, y)
	local wall = {body = Body.new(x, y, world, 500, 1000, 0.4, "wall")}
	wall.body.friction = 4
	table.insert(world.walls, wall)
	return wall
end

function Wall.drawWalls(walls, camera)
	for i = 1, #walls do
		local wall = walls[i]
		if wall.body.tile.visible then
			love.graphics.setColor(1, 1, 1, 1)
			Image.drawImage(Image.getImage("tiles/wall"), camera, wall.body.x, wall.body.y, 0)
		end
	end
end

return Wall