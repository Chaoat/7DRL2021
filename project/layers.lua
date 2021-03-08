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
addNewLayer("bullet", 		{true, false})
addNewLayer("character", 	{true, true, true})

function Layers.getAllLayers()
	return layerAddOrder
end

function Layers.getCollidingLayers(layer)
	return layerTables[layer]
end

return Layers