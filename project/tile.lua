local Tile = {}

function Tile.new(x, y, health, map)
	local tile = {x = x, y = y, map = map, health = health, bodies = {}, updatingLayers = {}, visible = false}
	local layers = Layers.getAllLayers()
	
	for i = 1, #layers do
		tile.bodies[layers[i]] = {}
		tile.updatingLayers[layers[i]] = false
	end
	
	return tile
end

function Tile.addBody(tile, body)
	table.insert(tile.bodies[body.layer], body)
end

function Tile.cleanTile(tile, layer)
	local i = 1
	while i <= #tile.bodies[layer] do
		local body = tile.bodies[layer][i]
		if not body.destroy and Tile.compare(body.tile, tile) then
			i = i + 1
		else
			--print(tile.x .. ":" .. tile.y .. " removed body " .. tile.bodies[layer][i].ID)
			table.remove(tile.bodies[layer], i)
		end
	end
	tile.updatingLayers[layer] = false
end

function Tile.compare(tile1, tile2)
	if tile1 and tile2 and tile1.x == tile2.x and tile1.y == tile2.y then
		return true
	end
	return false
end

function Tile.draw(tile, camera)
	if tile.visible then
		local tileImage = Image.getImage("tiles/floor")
		local parity = (tile.x + tile.y)%2
		local colour = {0.8 - 0.4*parity, 0.8 - 0.4*parity, 0.8 - 0.4*parity, 1}
		
		love.graphics.setColor(colour)
		Image.drawImage(tileImage, camera, tile.x, tile.y, 0)
	end
end

return Tile