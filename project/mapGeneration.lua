local MapGeneration = {}

local function newMapStructure(width, height)
	local mapStructure = {nodes = {}, width = width, height = height}
	for i = 1, width do
		mapStructure.nodes[i] = {}
		for j = 1, height do
			mapStructure.nodes[i][j] = false
		end
	end
	return mapStructure
end
local function newMapNode(mapStructure, x, y)
	local mapNode = {x = x, y = y, topOpen = false, botOpen = false, rightOpen = false, leftOpen = false}
	mapStructure.nodes[x][y] = mapNode
	return mapNode
end
local function linkNodes(mapStructure, x1, y1, x2, y2)
	local node1 = mapStructure.nodes[x1][y1]
	local node2 = mapStructure.nodes[x2][y2]
	if node1 and node2 then
		if x1 > x2 then
			node1.leftOpen = true
			node2.rightOpen = true
		elseif x2 > x1 then
			node1.rightOpen = true
			node2.leftOpen = true
		elseif y1 > y2 then
			node1.topOpen = true
			node2.botOpen = true
		elseif y2 > y1 then
			node1.botOpen = true
			node2.topOpen = true
		end
	end
end
local function isolatedArea(mapStructure, x1, y1, x2, y2, nEntrances)
	for i = x1, x2 do
		for j = y1, y2 do
			local node = newMapNode(mapStructure, i, j)
		end
	end
	for i = x1, x2 - 1 do
		for j = y1, y2 do
			linkNodes(mapStructure, i, j, i + 1, j)
			linkNodes(mapStructure, j, i, j, i + 1)
		end
	end
	
	local possibleEntrances = {}
	for i = x1, x2 do
		table.insert(possibleEntrances, {i, y1, i, y1 - 1})
		table.insert(possibleEntrances, {i, y2, i, y2 + 1})
	end
	for j = y1, y2 do
		table.insert(possibleEntrances, {x1, j, x1 - 1, j})
		table.insert(possibleEntrances, {x2, j, x2 + 1, j})
	end
	local chosenEntrances = Random.nRandomFromList(possibleEntrances, nEntrances)
	
	for i = 1, #chosenEntrances do
		local cE = chosenEntrances[i]
		linkNodes(mapStructure, cE[1], cE[2], cE[3], cE[4])
	end
end
function MapGeneration.generateMapStructure(radius)
	local pathLength = 0
	local requiredLength = 2*radius
	while pathLength < requiredLength do
		local mapStructure = newMapStructure(2*radius + 3, 2*radius + 3)
		
		local centerCoords = {radius + 1, radius + 1}
		local centerSanctum = {centerCoords[1] - 1, centerCoords[2] - 1, centerCoords[1] + 1, centerCoords[2] + 1}
		
		local nodeList = {}
		local function addNodeToQueue(nodeCoords, parentPosition)
			table.insert(nodeList, {coords = nodeCoords, parent = parentPosition})
		end
		
		addNodeToQueue({centerSanctum[1] - 3, centerSanctum[2]}, nil)
		
		while #nodeList > 0 do
			local nodeEntry, index = Random.randomFromList(nodeList)
			local x = nodeEntry.coords[1]
			local y = nodeEntry.coords[2]
			local dist = math.abs(x - centerCoords[1]) + math.abs(y - centerCoords[2])
			if dist <= radius and not (x >= centerSanctum[1] and x <= centerSanctum[3] and y >= centerSanctum[2] and y <= centerSanctum[4]) then
				if not mapStructure.nodes[x][y] then
					local node = newMapNode(mapStructure, x, y)
					if nodeEntry.parent then
						linkNodes(mapStructure, x, y, nodeEntry.parent[1], nodeEntry.parent[2])
					end
					
					addNodeToQueue({x + 1, y}, {x, y})
					addNodeToQueue({x - 1, y}, {x, y})
					addNodeToQueue({x, y + 1}, {x, y})
					addNodeToQueue({x, y - 1}, {x, y})
				else
					if nodeEntry.parent and math.random() <= 0.2 then
						linkNodes(mapStructure, x, y, nodeEntry.parent[1], nodeEntry.parent[2])
					end
				end
			end
			
			table.remove(nodeList, index)
		end
		
		isolatedArea(mapStructure, centerSanctum[1], centerSanctum[2], centerSanctum[3], centerSanctum[4], 3)
		
		local path = MapGeneration.distanceBetween(mapStructure, {2*radius + 1, radius + 1}, centerCoords)
		if path then
			pathLength = #path
		end
		
		if pathLength >= requiredLength then
			mapStructure.nodes[2*radius + 1][radius + 1].rightOpen = true
			mapStructure.nodes[radius + 1][2*radius + 1].botOpen = true
			
			return mapStructure
		end
	end
end

function MapGeneration.distanceBetween(mapStructure, fromCoords, toCoords)
	local checkedCoords = {}
	for i = 1, mapStructure.width do
		checkedCoords[i] = {}
		for j = 1, mapStructure.height do
			checkedCoords[i][j] = false
		end
	end
	
	
	local nodesToCheck = {{fromCoords[1], fromCoords[2]}}
	checkedCoords[fromCoords[1]][fromCoords[2]] = "origin"
	
	local function addNode(pX, pY, newX, newY)
		if not checkedCoords[newX][newY] then
			checkedCoords[newX][newY] = {pX, pY}
			table.insert(nodesToCheck, {newX, newY})
		end
	end
	local function breadthFS(x, y)
		local node = mapStructure.nodes[x][y]
		if node then
			if x == toCoords[1] and y == toCoords[2] then
				return true
			end
			
			if node.leftOpen then
				addNode(x, y, x - 1, y)
			end
			if node.rightOpen then
				addNode(x, y, x + 1, y)
			end
			if node.topOpen then
				addNode(x, y, x, y - 1)
			end
			if node.botOpen then
				addNode(x, y, x, y + 1)
			end
		end
		return false
	end
	
	local foundPath = nil
	while #nodesToCheck > 0 and not foundPath do
		if breadthFS(nodesToCheck[1][1], nodesToCheck[1][2]) then
			local nX = nodesToCheck[1][1]
			local nY = nodesToCheck[1][2]
			foundPath = {mapStructure.nodes[nX][nY]}
			local parent = checkedCoords[nX][nY]
			while parent ~= "origin" do
				table.insert(foundPath, 1, {mapStructure.nodes[parent[1]][parent[2]]})
				parent = checkedCoords[parent[1]][parent[2]]
			end
		end
		table.remove(nodesToCheck, 1)
	end
	
	return foundPath
end

function MapGeneration.testDrawStructure(x, y, mapStructure)
	for i = 1, mapStructure.width do
		for j = 1, mapStructure.height do
			local node = mapStructure.nodes[i][j]
			if node then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.circle("fill", 16*i, 16*j, 3)
				if node.topOpen then
					love.graphics.line(16*i, 16*j, 16*i, 16*j - 8)
				end
				if node.botOpen then
					love.graphics.line(16*i, 16*j, 16*i, 16*j + 8)
				end
				if node.rightOpen then
					love.graphics.line(16*i, 16*j, 16*i + 8, 16*j)
				end
				if node.leftOpen then
					love.graphics.line(16*i, 16*j, 16*i - 8, 16*j)
				end
			end
		end
	end
end

function MapGeneration.generateMapFromStructure(mapStructure, segmentSize, world)
	local map = Map.new(segmentSize*mapStructure.width, segmentSize*mapStructure.height, mapStructure)
	world.map = map
	
	local function placeWall(x1, y1, x2, y2)
		for i = x1, x2 do
			for j = y1, y2 do
				Wall.new(world, i, j)
			end
		end
	end
	local function generateWall(x, y)
		local node = mapStructure.nodes[x][y]
		local botOpen = false
		local rightOpen = false
		if node then
			botOpen = node.botOpen
			rightOpen = node.rightOpen
			Map.iterateOverTileRange(map, {map.minCoords[1] + segmentSize*x, map.minCoords[1] + segmentSize*(x + 1)}, {map.minCoords[2] + segmentSize*y, map.minCoords[2] + segmentSize*(y + 1)}, function(tile)
				Tile.reFloor(tile, 100)
			end)
		end
		
		local placeCorner = false
		if y + 1 <= mapStructure.height and mapStructure.nodes[x][y + 1] or node then
			placeCorner = true
			if not botOpen then
				local x1 = map.minCoords[1] + segmentSize*x + 1
				local y1 = map.minCoords[2] + segmentSize*(y + 1)
				local x2 = map.minCoords[1] + segmentSize*(x + 1) - 1
				local y2 = map.minCoords[2] + segmentSize*(y + 1)
				placeWall(x1, y1, x2, y2)
			end
		end
		if x + 1 <= mapStructure.width and mapStructure.nodes[x + 1][y] or node then
			placeCorner = true
			if not rightOpen then
				local x1 = map.minCoords[1] + segmentSize*(x + 1)
				local y1 = map.minCoords[2] + segmentSize*y + 1
				local x2 = map.minCoords[1] + segmentSize*(x + 1)
				local y2 = map.minCoords[2] + segmentSize*(y + 1) - 1
				placeWall(x1, y1, x2, y2)
			end
		end
		if x + 1 <= mapStructure.width and y + 1 <= mapStructure.height and mapStructure.nodes[x + 1][y + 1] or node then
			placeCorner = true
		end
		if placeCorner then
			Wall.new(world, map.minCoords[1] + segmentSize*(x + 1), map.minCoords[2] + segmentSize*(y + 1))
		end
	end
	for i = 1, mapStructure.width do
		for j = 1, mapStructure.height do
			generateWall(i, j)
		end
	end
end

return MapGeneration