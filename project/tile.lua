local Tile = {}

local segmentSize
local tileCanvas
function Tile.initTileCanvas(width, height, sS)
	segmentSize = sS
	tileCanvas = love.graphics.newCanvas(width - 2*GlobalTileDims[1]*sS, height - 2*GlobalTileDims[2]*sS)
	love.graphics.setCanvas(tileCanvas)
	love.graphics.setCanvas()
end

function Tile.new(x, y, health, map)
	local parity = (x + y)%2
	local colour = {0.5 - 0.3*parity, 0.5 - 0.3*parity, 0.5 - 0.3*parity, 1}
	
	local tile = {x = x, y = y, map = map, health = health, bodies = {}, updatingLayers = {}, visible = false, remembered = false, floored = false, danger = {}, trailColour = {0, 0, 0, 0}, tileColour = colour, lastTrailUpdate = GlobalClock}
	local layers = Layers.getAllLayers()
	
	for i = 1, #layers do
		tile.bodies[layers[i]] = {}
		tile.updatingLayers[layers[i]] = false
	end
	
	return tile
end

function Tile.damage(tile, damage, world)
	if tile.floored then
		tile.health = math.max(tile.health - damage, 0)
		
		if tile.health == 0 then
			Tile.deFloor(tile)
			Tile.updateCanvas(world.map, globalGame.mainCamera)
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
	local parity = (tile.x + tile.y)%2
	local colour = {0.5 - 0.3*parity, 0.5 - 0.3*parity, 0.5 - 0.3*parity, 1}
	tile.tileColour = colour
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
			for j = 1, #tile.bodies[collidingLayers[i]] do
				if not tile.bodies[collidingLayers[i]][j].simulation then
					return true
				end
			end
		end
	end
	return false
end

function Tile.seeTile(tile)
	tile.visible = true
	tile.remembered = true
	
	for i = 1, #tile.bodies["character"] do
		local body = tile.bodies["character"][i]
		--print(i)
		if body.parent.parent then
			Enemy.warnEnemy(body.parent.parent, 3)
		end
	end
end

function Tile.checkDangerous(tile)
	local i = #tile.danger
	while i > 0 do
		local danger = tile.danger[i]
		
		if danger.destroy then
			table.remove(tile.danger, i)
		else
			return true
		end
		
		i = i - 1
	end
	return false
end

function Tile.updateCanvas(map, camera)
	love.graphics.setCanvas(tileCanvas)
	love.graphics.clear()
	
	local xRange = {camera.x - math.ceil(0.5*camera.canvasDims[1]/camera.tileDims[1]), camera.x + math.ceil(0.5*camera.canvasDims[1]/camera.tileDims[1])}
	local yRange = {camera.y - math.ceil(0.5*camera.canvasDims[2]/camera.tileDims[2]), camera.y + math.ceil(0.5*camera.canvasDims[2]/camera.tileDims[2])}
	
	Map.iterateOverTileRange(map, xRange, yRange, function(tile)
		Tile.draw(tile, camera)
	end)
	love.graphics.setCanvas()
end

function Tile.draw(tile, camera)
	if (tile.visible or tile.remembered) then
		if tile.floored then
			local tileImage = Image.getImage("tiles/floor")
			
			local cColour = {tile.tileColour[1], tile.tileColour[2], tile.tileColour[3], 1}
			if not tile.visible then
				cColour[1] = 0.1*cColour[1]
				cColour[2] = 0.1*cColour[2]
				cColour[3] = 0.1*cColour[3]
			end
			
			love.graphics.setColor(cColour)
			local drawX = tileCanvas:getWidth()/2 + camera.tileDims[1]*(tile.x - 1)
			local drawY = tileCanvas:getHeight()/2 + camera.tileDims[2]*(tile.y - 1)
			love.graphics.rectangle("fill", drawX, drawY, GlobalTileDims[1], GlobalTileDims[2])
		end
	else
		if tile.floored then
			local drawX = tileCanvas:getWidth()/2 + camera.tileDims[1]*(tile.x - 1)
			local drawY = tileCanvas:getHeight()/2 + camera.tileDims[2]*(tile.y - 1)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.rectangle("fill", drawX, drawY, GlobalTileDims[1], GlobalTileDims[2])
		end
	end
end

function Tile.drawOverlays(tile, camera)
	local gc = GlobalClock
	if (tile.visible or tile.remembered) then
		if tile.trailColour[4] > 0 then
			local dt = gc - tile.lastTrailUpdate
			tile.trailColour[4] = math.max(tile.trailColour[4] - dt, 0)
			
			Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
				love.graphics.setColor(tile.trailColour)
				love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
			end)
		end
		tile.lastTrailUpdate = gc
	end
end

function Tile.drawCanvas(map, camera)
	love.graphics.setColor(1, 1, 1, 1)
	Camera.drawTo(camera, map.minCoords[1] + segmentSize + 0.5, map.minCoords[2] + segmentSize + 0.5, 
	function(drawX, drawY)
		love.graphics.draw(tileCanvas, Misc.round(drawX), Misc.round(drawY))
	end)
	
	--local xOff = math.max(love.graphics.getWidth() - 1000, 0)/2
	--local yOff = math.max(love.graphics.getHeight() - 1000, 0)/2
	--
	--local drawX, drawY = Camera.getDrawCoords(map.minCoords[1] + segmentSize + 0.5, map.minCoords[2] + segmentSize + 0.5, camera)
	--love.graphics.setColor(1, 1, 1, 1)
	--love.graphics.draw(tileCanvas, Misc.round(drawX + xOff), Misc.round(drawY + yOff))
end

return Tile