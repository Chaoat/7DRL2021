local Layers = {}

local layerAddOrder = {}
local layers = {}
local layerTables = {}
local function addNewLayer(layerName, collisions)
	for i = 1, #layerAddOrder do
		layers[layerAddOrder[i]][layerName] = collisions[i]
		if collisions[i] then
			table.insert(layerTables[layerAddOrder[i]], layerName)
		end
	end
	
	table.insert(layerAddOrder, layerName)
	local layer = {}
	local layerTable = {}
	for i = 1, #layerAddOrder do
		layer[layerAddOrder[i]] = collisions[i]
		if collisions[i] then
			table.insert(layerTable, layerAddOrder[i])
		end
	end
	
	layers[layerName] = layer
	layerTables[layerName] = layerTable
end

addNewLayer("wall", 		{true})
addNewLayer("bullet", 		{true, 	false})
addNewLayer("character", 	{true, 	true, 	true})
addNewLayer("explosion", 	{true, 	true, 	true, 	false})
addNewLayer("pathfinder", 	{true, 	false, 	true, 	false, 	false})
addNewLayer("bomb", 		{true, 	true, 	true, 	true, 	false, 	true})
addNewLayer("item", 		{true, 	false, 	false, 	false, 	false, 	false, 	false})
addNewLayer("shield", 		{false,	true, 	false, 	true, 	false, 	true, 	false,	false})
addNewLayer("particle", 		{true,	false, 	false, 	false, 	false, 	false, 	false,	false,	false})

function Layers.getAllLayers()
	return layerAddOrder
end

function Layers.getCollidingLayers(layer)
	return layerTables[layer]
end

return Layers