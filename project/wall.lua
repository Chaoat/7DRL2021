local Wall = {}

local neighbourCoords = {
{1, 0}, 
{0, 1},
{-1, 0},
{0, -1}}

local function oppositeI(index)
	return (index + 1)%4 + 1
end

local function resetNeighbours(wall)
	for i = 1, 4 do
		if wall.neighbours[i] then
			wall.neighbours[i].parent.neighbours[oppositeI(i)] = false
			wall.neighbours[i] = false
		end
	end
end

local function iterateOverNeighbours(wall, func)
	--func(neighbourI, neighbourTile)
	for i = 1, 4 do
		local xOff = neighbourCoords[i][1]
		local yOff = neighbourCoords[i][2]
		
		local tile = Map.getTile(wall.body.map, wall.body.tile.x + xOff, wall.body.tile.y + yOff)
		func(i, tile)
	end
end

local function findNeighbours(wall)
	local map = wall.body.map
	iterateOverNeighbours(wall, 
	function(neighbourI, tile)
		if #tile.bodies["wall"] > 0 then
			local wallBody = tile.bodies["wall"][1]
			if wallBody.ID ~= wall.body.ID then
				wall.neighbours[neighbourI] = wallBody
				wallBody.parent.neighbours[oppositeI(neighbourI)] = wall.body
			end
		end
	end)
end

function Wall.new(world, x, y)
	local wall = {body = Body.new(x, y, world, 200, 40, 0.4, "wall"), neighbours = {false, false, false, false}}
	wall.body.parent = wall
	
	local function onMove(oldTile)
		resetNeighbours(wall)
		findNeighbours(wall)
	end
	
	Body.addMoveCallback(wall.body, onMove)
	
	findNeighbours(wall)
	wall.body.friction = 4
	table.insert(world.walls, wall)
	return wall
end

local function vertex(body, xDir, yDir, camera)
	if body then
		return {body.x + xDir*0.5, body.y + yDir*0.5}
	end
end

local function addVertex(vertexList, vertex)
	if vertex then
		table.insert(vertexList, vertex)
	end
end

function Wall.drawWalls(walls, camera)
	for i = 1, #walls do
		local wall = walls[i]
		if (wall.body.tile.visible or wall.body.tile.remembered) and not wall.body.destroy then
			local topRight = {}
			addVertex(topRight, vertex(wall.neighbours[1], -1, -1, camera))
			addVertex(topRight, vertex(wall.neighbours[4], 1, 1, camera))
			addVertex(topRight, vertex(wall.body, 1, -1, camera))
			local botRight = {}
			addVertex(botRight, vertex(wall.neighbours[1], -1, 1, camera))
			addVertex(botRight, vertex(wall.neighbours[2], 1, -1, camera))
			addVertex(botRight, vertex(wall.body, 1, 1, camera))
			local botLeft = {}
			addVertex(botLeft, vertex(wall.neighbours[3], 1, 1, camera))
			addVertex(botLeft, vertex(wall.neighbours[2], -1, -1, camera))
			addVertex(botLeft, vertex(wall.body, -1, 1, camera))
			local topLeft = {}
			addVertex(topLeft, vertex(wall.neighbours[3], 1, -1, camera))
			addVertex(topLeft, vertex(wall.neighbours[4], -1, 1, camera))
			addVertex(topLeft, vertex(wall.body, -1, -1, camera))
			local compiled = {topRight, botRight, botLeft, topLeft}
			local vertices = {}
			for j = 1, 4 do
				local avgX = 0
				local avgY = 0
				for k = 1, #compiled[j] do
					avgX = avgX + compiled[j][k][1]
					avgY = avgY + compiled[j][k][2]
				end
				avgX = avgX/#compiled[j]
				avgY = avgY/#compiled[j]
				
				avgX, avgY = Camera.getDrawCoords(avgX, avgY, camera)
				
				table.insert(vertices, avgX)
				table.insert(vertices, avgY)
			end
			
			--local r = 0
			--if wall.neighbours[1] then
			--	r = 1
			--end
			--local g = 0
			--if wall.neighbours[2] then
			--	g = 1
			--end
			--local b = 0
			--if wall.neighbours[3] then
			--	b = 1
			--end
			--local a = 0.8
			--if wall.neighbours[4] then
			--	a = 1
			--end
			
			local alpha = 1
			if not wall.body.tile.visible then
				alpha = 0.2
			end
			
			love.graphics.setLineWidth(2)
			love.graphics.setLineStyle("rough")
			Camera.drawTo(camera, wall.body.x, wall.body.y, function(drawX, drawY)
				--love.graphics.setColor(r, g, b, a)
				love.graphics.setColor(0.8, 0.8, 0.8, alpha)
				love.graphics.polygon("fill", vertices)
				love.graphics.setColor(0.4, 0.4, 0.4, alpha)
				love.graphics.polygon("line", vertices)
			end)
		end
	end
end

return Wall