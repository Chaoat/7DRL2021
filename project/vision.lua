local Vision = {}

local function visionNode(xOff, yOff)
	local node = {xOff = xOff, yOff = yOff, dist = math.sqrt(xOff^2 + yOff^2), children = {}}
	return node
end
local function generateVisionTree(radius)
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

local visionTrees = {}
function Vision.checkVisible(world, centerX, centerY, radius)
	local descendVisionTree
	descendVisionTree = function(visionNode)
		local map = world.map
		local tile = Map.getTile(map, centerX + visionNode.xOff, centerY + visionNode.yOff)
		Tile.seeTile(tile)
		
		if #tile.bodies["wall"] == 0 then
			for i = 1, #visionNode.children do
				descendVisionTree(visionNode.children[i])
			end
		end
	end
	
	if not visionTrees[radius] then
		visionTrees[radius] = generateVisionTree(radius)
	end
	descendVisionTree(visionTrees[radius])
end

function Vision.getTilesInVision(world, x, y, radius, condition)
	--condition(tile)
	local tiles = {}
	
	local map = world.map
	if not visionTrees[radius] then
		visionTrees[radius] = generateVisionTree(radius)
	end
	local checking = {visionTrees[radius]}
	while #checking > 0 do
		local visionNode = checking[1]
		local tile = Map.getTile(map, x + visionNode.xOff, y + visionNode.yOff)
		if tile then
			if #tile.bodies["wall"] == 0 then
				if condition and condition(tile) then
					table.insert(tiles, tile)
				end
				
				for i = 1, #visionNode.children do
					table.insert(checking, visionNode.children[i])
				end
			end
		end
		
		table.remove(checking, 1)
	end
	
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

return Vision