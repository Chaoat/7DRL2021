local Vision = {}

local function visionNode(xOff, yOff)
	local node = {xOff = xOff, yOff = yOff, dist = math.sqrt(xOff^2 + yOff^2), children = {}, blockers = {}, blocking = {}, checkParity = 0, blocked = false}
	return node
end
local function generateVisionTreeOLD(radius)
	local nodeMap = {}
	for i = -radius, radius do
		nodeMap[i] = {}
		for j = -radius, radius do
			nodeMap[i][j] = visionNode(i, j)
		end
	end
	
	for i = -radius, radius do
		for j = -radius, radius do
			if i ~= 0 or j ~= 0 then
				local angle = math.atan2(j, i) + math.pi
				local xOff, yOff = Misc.angleToDir(angle)
				local pX = i + xOff
				local pY = j + yOff
				
				table.insert(nodeMap[pX][pY].children, nodeMap[i][j])
			end
		end
	end
	--Multiple parents would do a good bit towards fixing the square vision
	
	return nodeMap[0][0]
end

local visionTree = {}
do --initVisionTree
	visionTree[0] = {}
	visionTree[0][0] = visionNode(0, 0)
end

local visionTreeSize = 0
local function expandVisionTree(radius)
	if radius > visionTreeSize then
		for i = -radius, radius do
			if math.abs(i) > visionTreeSize then
				visionTree[i] = {}
			end
		end
		
		local function processFromPoint(x, y)
			local line = Misc.plotLine(x, y, 0, 0)
			
			visionTree[x][y] = visionNode(x, y)
			
			--print(x .. "|" .. y)
			for i = 1, #line - 1 do
				--print(line[i][1] .. ":" .. line[i][2])
				local current = visionTree[line[i][1]][line[i][2]]
				local parent = visionTree[line[i + 1][1]][line[i + 1][2]]
				
				if parent.dist < current.dist then
					local present = false
					for j = 1, #parent.children do
						local child = parent.children[j]
						if child.xOff == line[i][1] and child.yOff == line[i][2] then
							present = true
							break
						end
					end
					
					if not present then
						table.insert(parent.children, current)
					end
				end
			end
			
			for i = 2, #line do
				local lineTile = visionTree[line[i][1]][line[i][2]]
				table.insert(lineTile.blocking, visionTree[x][y])
				table.insert(visionTree[x][y].blockers, lineTile)
			end
		end
		
		for j = visionTreeSize + 1, radius do
			for i = -j, j - 1 do
				processFromPoint(i, -j)
				processFromPoint(i + 1, j)
				processFromPoint(-j, i + 1)
				processFromPoint(j, i)
			end
		end
		
		visionTreeSize = radius
	end
end

local currentCheckParity = 0

function Vision.getTilesInVision(world, centerX, centerY, radius, condition)
	currentCheckParity = (currentCheckParity + 1)%2
	--condition(tile)
	local tiles = {}
	
	local map = world.map
	expandVisionTree(radius)
	
	local function checkNode(x, y)
		local node = visionTree[x][y]
		if node.checkParity ~= currentCheckParity then
			node.checkParity = radius + visionTreeSize*currentCheckParity + 1
			
			node.blocked = false
			for i = 1, #node.blockers do
				if node.blockers[i].blocked and node.blockers[i].checkParity == node.checkParity then
					node.blocked = true
					break
				end
			end
			
			if not node.blocked then
				local tile = Map.getTile(map, centerX + x, centerY + y)
				if not condition or condition(tile) then
					table.insert(tiles, tile)
				end
				if #tile.bodies["wall"] > 0 then
					node.blocked = true
					for i = 1, #node.blocking do
						node.blocking[i].blocked = true
						node.blocking[i].checkParity = radius + visionTreeSize*currentCheckParity + 1
					end
				end
			end
		end
	end
	
	for r = 1, radius do
		for i = -r, r - 1 do
			checkNode(i, -r)
			checkNode(i + 1, r)
			checkNode(-r, i + 1)
			checkNode(r, i)
		end
	end
	
	return tiles
end

function Vision.checkVisible(world, centerX, centerY, radius)
	local tiles = Vision.getTilesInVision(world, centerX, centerY, radius)
	table.insert(tiles, Map.getTile(world.map, centerX, centerY))
	for i = 1, #tiles do
		Tile.seeTile(tiles[i])
	end
end

function Vision.findVisibleEnemies(world, x, y, range)
	local tiles = Vision.getTilesInVision(world, x, y, range, function(tile)
		return #tile.bodies["character"] > 0
	end)
	
	local bodies = {}
	for i = 1, #tiles do
		local tile = tiles[i]
		local body = tile.bodies["character"][1]
		if body.parent.parent and not body.simulation then
			table.insert(bodies, body)
		end
	end
	return bodies
end

function Vision.findClosestEnemy(world, x, y, range)
	local enemyBodies = Vision.findVisibleEnemies(world, x, y, range)
	if #enemyBodies > 0 then
		return enemyBodies[1]
	end
	return false
end

function Vision.debugDrawRoute(tileX, tileY, centerX, centerY, camera)
	expandVisionTree(math.max(math.abs(tileX), math.abs(tileY)))
	local visionNode = visionTree[tileX][tileY]
	
	local cX, cY = Camera.getDrawCoords(centerX + tileX, centerY + tileY, camera)
	for i = 1, #visionNode.blockers do
		local blocker = visionNode.blockers[i]
		love.graphics.setColor(1, 0, i%2, 1)
		local nX, nY = Camera.getDrawCoords(centerX + blocker.xOff, centerY + blocker.yOff, camera)
		love.graphics.line(cX, cY, nX, nY)
		
		cX = nX
		cY = nY
	end
end

function Vision.fullResetVision(map)
	Map.iterateOverTileRange(map, {map.minCoords[1], map.maxCoords[1]}, {map.minCoords[2], map.maxCoords[2]}, 
	function(tile)
		tile.visible = false
	end)
end

return Vision