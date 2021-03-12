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
			node.checkParity = currentCheckParity
			
			node.blocked = false
			for i = 1, #node.blockers do
				if node.blockers[i].blocked then
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
						node.blocking[i].checkParity = currentCheckParity
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

function Vision.checkVisibleOLD(world, centerX, centerY, radius)
	local descendVisionTree
	descendVisionTree = function(visionNode)
		visionNode.checkParity = currentCheckParity
		
		local map = world.map
		local tile = Map.getTile(map, centerX + visionNode.xOff, centerY + visionNode.yOff)
		Tile.seeTile(tile)
		
		if #tile.bodies["wall"] == 0 then
			for i = 1, #visionNode.children do
				--print(visionNode.children[i].xOff .. ":" .. visionNode.children[i].yOff)
				local child = visionNode.children[i]
				if child.checkParity ~= currentCheckParity then
					descendVisionTree(visionNode.children[i])
				end
			end
		end
	end
	
	expandVisionTree(radius)
	descendVisionTree(visionTree[0][0])
	
	currentCheckParity = (currentCheckParity + 1)%2
end

function Vision.getTilesInVisionOLD(world, x, y, radius, condition)
	--condition(tile)
	local tiles = {}
	
	local map = world.map
	expandVisionTree(radius)
	local checking = {visionTree[0][0]}
	while #checking > 0 do
		local visionNode = checking[1]
		visionNode.checkParity = currentCheckParity
		local tile = Map.getTile(map, x + visionNode.xOff, y + visionNode.yOff)
		if tile then
			if #tile.bodies["wall"] == 0 then
				if condition and condition(tile) then
					table.insert(tiles, tile)
				end
				
				for i = 1, #visionNode.children do
					local child = visionNode.children[i]
					if child.checkParity ~= currentCheckParity then
						table.insert(checking, child)
					end
				end
			end
		end
		
		table.remove(checking, 1)
	end
	
	currentCheckParity = (currentCheckParity + 1)%2
	
	return tiles
end

function Vision.findClosestEnemy(world, x, y, range)
	local tiles = Vision.getTilesInVision(world, x, y, range, function(tile)
		return #tile.bodies["character"] > 0
	end)
	
	for i = 1, #tiles do
		local tile = tiles[i]
		local body = tile.bodies["character"][1]
		if body.parent.parent then
			return body
		end
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

return Vision