local Pathfinding = {}

local function expandPathfindingMap(pathfindingMap, xOff, yOff)
	if xOff < pathfindingMap.bounds.x[1] then
		for i = xOff, pathfindingMap.bounds.x[1] - 1 do
			pathfindingMap.distHeuristic[i] = {}
			for j = pathfindingMap.bounds.y[1], pathfindingMap.bounds.y[2] do
				local dirX, dirY = Misc.angleToDir(math.atan2(j, i) + math.pi)
				pathfindingMap.distHeuristic[i][j] = {dist = math.sqrt(i^2 + j^2), dir = {dirX, dirY}}
			end
		end
		pathfindingMap.bounds.x[1] = xOff
	end
	if xOff > pathfindingMap.bounds.x[2] then
		for i = pathfindingMap.bounds.x[2] + 1, xOff do
			pathfindingMap.distHeuristic[i] = {}
			for j = pathfindingMap.bounds.y[1], pathfindingMap.bounds.y[2] do
				local dirX, dirY = Misc.angleToDir(math.atan2(j, i) + math.pi)
				pathfindingMap.distHeuristic[i][j] = {dist = math.sqrt(i^2 + j^2), dir = {dirX, dirY}}
			end
		end
		pathfindingMap.bounds.x[2] = xOff
	end
	
	if yOff < pathfindingMap.bounds.y[1] then
		for i = pathfindingMap.bounds.x[1], pathfindingMap.bounds.x[2] do
			for j = yOff, pathfindingMap.bounds.y[1] - 1 do
				local dirX, dirY = Misc.angleToDir(math.atan2(j, i) + math.pi)
				pathfindingMap.distHeuristic[i][j] = {dist = math.sqrt(i^2 + j^2), dir = {dirX, dirY}}
			end
		end
		pathfindingMap.bounds.y[1] = yOff
	end
	if yOff > pathfindingMap.bounds.y[2] then
		for i = pathfindingMap.bounds.x[1], pathfindingMap.bounds.x[2] do
			for j = pathfindingMap.bounds.y[2] + 1, yOff do
				local dirX, dirY = Misc.angleToDir(math.atan2(j, i) + math.pi)
				pathfindingMap.distHeuristic[i][j] = {dist = math.sqrt(i^2 + j^2), dir = {dirX, dirY}}
			end
		end
		pathfindingMap.bounds.y[2] = yOff
	end
end

local function newPathTile()
	local tile = {targetTile = false, child = false, alreadyChecked = false}
	return tile
end

function Pathfinding.newPathfindingMap(map)
	local pathfindingMap = {map = map, distHeuristic = {}, tiles = {}, bounds = {x = {0, -1}, y = {0, -1}}}
	
	for i = map.minCoords[1], map.maxCoords[1] do
		pathfindingMap.tiles[i] = {}
		for j = map.minCoords[2], map.maxCoords[2] do
			pathfindingMap.tiles[i][j] = newPathTile()
		end
	end
	
	expandPathfindingMap(pathfindingMap, 0, 0)
	
	return pathfindingMap
end

function Pathfinding.findPath(pathfindingMap, startingCoords, endingCoords, endDistance)
	local toCheck = {}
	local function newNode(x, y, parent)
		if x >= pathfindingMap.map.minCoords[1] and x <= pathfindingMap.map.maxCoords[1] and y >= pathfindingMap.map.minCoords[2] and y <= pathfindingMap.map.maxCoords[2] then
			local pTile = pathfindingMap.tiles[x][y]
			if not pTile.alreadyChecked then
				local xOff = Misc.round(x - endingCoords[1])
				local yOff = Misc.round(y - endingCoords[2])
				expandPathfindingMap(pathfindingMap, xOff, yOff)
				
				local node = {x = x, y = y, parent = parent, negDist = -pathfindingMap.distHeuristic[xOff][yOff].dist}
				pTile.alreadyChecked = true
				Misc.binaryInsert(toCheck, node, "negDist")
				
				if pTile.targetTile and pTile.targetTile[1] == endingCoords[1] and pTile.targetTile[2] == endingCoords[2] and not Tile.checkBlocking(Map.getTile(pathfindingMap.map, pTile.child[1], pTile.child[2]), "character") then
					newNode(pTile.child[1], pTile.child[2], node)
				end
			end
		end
	end
	newNode(startingCoords[1], startingCoords[2], nil)
	
	local pathFound = false
	local function addToPath(checking, child)
		local pTile = pathfindingMap.tiles[checking.x][checking.y]
		if child then
			pTile.targetTile = endingCoords
			pTile.child = {child.x, child.y}
		end
		
		if checking.parent then
			addToPath(checking.parent, checking)
		end
		--print(checking.x .. ":" .. checking.y)
		table.insert(pathFound, {checking.x, checking.y})
	end
	
	while not pathFound and #toCheck > 0 do
		local checking = toCheck[#toCheck]
		table.remove(toCheck, #toCheck)
		
		if math.floor(-checking.negDist) <= endDistance then
			pathFound = {}
			addToPath(checking, nil)
		else
			for i = -1, 1 do
				for j = -1, 1 do
					local x = checking.x + i
					local y = checking.y + j
					if not Tile.checkBlocking(Map.getTile(pathfindingMap.map, x, y), "pathfinder") then
						newNode(x, y, checking)
					end
				end
			end
		end
	end
	
	for i = pathfindingMap.map.minCoords[1], pathfindingMap.map.maxCoords[1] do
		for j = pathfindingMap.map.minCoords[2], pathfindingMap.map.maxCoords[2] do
			pathfindingMap.tiles[i][j].alreadyChecked = false
		end
	end
	
	return pathFound
end

function Pathfinding.visualizeMap(pM, centerBody, camera)
	for i = pM.bounds.x[1], pM.bounds.x[2] do
		for j = pM.bounds.y[1], pM.bounds.y[2] do
			local heuristic = pM.distHeuristic[i][j]
			Camera.drawTo(camera, centerBody.tile.x + i, centerBody.tile.y + j, function(drawX, drawY)
				love.graphics.setColor(1, 1, 1, 1)
				Font.setFont("437", 12)
				love.graphics.print(Misc.round(heuristic.dist), drawX, drawY)
				
				love.graphics.setColor(1, 0, 1, 1)
				love.graphics.circle("fill", drawX + 2*heuristic.dir[1], drawY + 2*heuristic.dir[2], 1)
				love.graphics.circle("fill", drawX + 4*heuristic.dir[1], drawY + 4*heuristic.dir[2], 1)
			end)
		end
	end
end

return Pathfinding