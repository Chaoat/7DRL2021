local Tile = {}

function Tile.new(x, y, health, map)
	local tile = {x = x, y = y, map = map, health = health, bodies = {}, updatingLayers = {}, visible = false, floored = false, trailColour = {0, 0, 0, 0}, lastTrailUpdate = GlobalClock}
	local layers = Layers.getAllLayers()
	
	for i = 1, #layers do
		tile.bodies[layers[i]] = {}
		tile.updatingLayers[layers[i]] = false
	end
	
	return tile
end

function Tile.damage(tile, damage)
	if tile.floored then
		tile.health = math.max(tile.health - damage, 0)
		
		if tile.health == 0 then
			Tile.deFloor(tile)
		end
	end
end

function Tile.addTrail(tile, trailColour)
	Misc.addColours(tile.trailColour, trailColour)
end

function Tile.deFloor(tile)
	tile.health = 0
	tile.floored = false
end

function Tile.reFloor(tile, health)
	tile.health = health
	tile.floored = true
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

function Tile.checkBlocking(tile, layer)
	local collidingLayers = Layers.getCollidingLayers(layer)
	for i = 1, #collidingLayers do
		if #tile.bodies[collidingLayers[i]] > 0 then
			return true
		end
	end
	return false
end

function Tile.draw(tile, camera)
	local gc = GlobalClock
	if tile.visible and tile.floored then
		local tileImage = Image.getImage("tiles/floor")
		local parity = (tile.x + tile.y)%2
		local colour = {0.5 - 0.3*parity, 0.5 - 0.3*parity, 0.5 - 0.3*parity, 1}
		
		Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
			love.graphics.setColor(colour)
			love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
			love.graphics.setColor({0.1, 0.1, 0.1, 1})
			love.graphics.rectangle("line", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
		end)
		
		if tile.trailColour[4] > 0 then
			local dt = gc - tile.lastTrailUpdate
			
			Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
				love.graphics.setColor(tile.trailColour)
				love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
			end)
			
			tile.trailColour[4] = math.max(tile.trailColour[4] - dt, 0)
		end
		tile.lastTrailUpdate = gc
	end
end

return Tile