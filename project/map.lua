local Map = {}

function Map.new(width, height)
	local map = {tileMap = {}, minCoords = {0, 0}, maxCoords = {0, 0}, cleaningTiles = {}}
	Map.expand(map, -math.ceil(width/2), -math.ceil(height/2), math.floor(width/2), math.floor(height/2))
	
	return map
end

function Map.addTileToCleanQueue(map, tile, layer)
	if not tile.updatingLayers[layer] then
		table.insert(map.cleaningTiles, {tile = tile, layer = layer})
	end
end

function Map.cleanAllTiles(map)
	for i = 1, #map.cleaningTiles do
		Tile.cleanTile(map.cleaningTiles[i].tile, map.cleaningTiles[i].layer)
	end
	map.cleaningTiles = {}
end

function Map.expand(map, x1, y1, x2, y2)
	for i = x1, x2 do
		if not map.tileMap[i] then
			map.tileMap[i] = {}
		end
		for j = y1, y2 do
			if not map.tileMap[i][j] then
				map.tileMap[i][j] = Tile.new(i, j, 100, map)
			end
		end
	end
	
	map.minCoords[1] = math.min(map.minCoords[1], x1)
	map.minCoords[2] = math.min(map.minCoords[2], y1)
	map.maxCoords[1] = math.max(map.maxCoords[1], x2)
	map.maxCoords[2] = math.max(map.maxCoords[2], y2)
end

function Map.iterateOverAllTiles(map, func)
	--func(tile)
	for i = map.minCoords[1], map.maxCoords[1] do
		for j = map.minCoords[2], map.maxCoords[2] do
			func(map.tileMap[i][j])
		end
	end
end

function Map.getTile(map, x, y)
	local tX = Misc.round(x)
	local tY = Misc.round(y)
	if tX >= map.minCoords[1] and tX <= map.maxCoords[1] and tY >= map.minCoords[2] and tY <= map.maxCoords[2] then
		return map.tileMap[tX][tY]
	else
		return Tile.new(x, y, 0, map)
	end
end

function Map.drawTiles(map, camera)
	Map.iterateOverAllTiles(map, function(tile)
		Tile.draw(tile, camera)
	end)
end

return Map