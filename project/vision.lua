local Vision = {}

local function visionNode(xOff, yOff)
	local node = {xOff = xOff, yOff = yOff, children = {}}
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
		tile.visible = true
		
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

return Vision