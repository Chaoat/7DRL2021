local Camera = {}

function Camera.new(cameraWidth, cameraHeight, tileWidth, tileHeight)
	local canvas = CanvasCache.getCanvas(cameraWidth, cameraHeight)
	local camera = {x = 0, y = 0, canvas = canvas, canvasDims = {cameraWidth, cameraHeight}, tileDims = {tileWidth, tileHeight}, followingBody = nil}
	camera.starSystem = Stars.newStarSystem(camera)
	return camera
end

function Camera.getDrawCoords(logicX, logicY, camera)
	local drawX = (logicX - camera.x)*camera.tileDims[1] + camera.canvasDims[1]/2
	local drawY = (logicY - camera.y)*camera.tileDims[2] + camera.canvasDims[2]/2
	return drawX, drawY
end

function Camera.screenToLogicCoords(x, y, cameraCorner, camera)
	x = x - cameraCorner[1]
	y = y - cameraCorner[2]
	
	return (x - camera.canvasDims[1]/2)/camera.tileDims[1] + camera.x, (y - camera.canvasDims[2]/2)/camera.tileDims[2] + camera.y
end

function Camera.moveCamera(camera, world, newX, newY)
	if Misc.round(camera.x) ~= Misc.round(newX) or Misc.round(camera.y) ~= Misc.round(newY) then

		Tile.updateCanvas(world.map, camera)
	end
	
	local xChange = newX - camera.x
	local yChange = newY - camera.y
	camera.starSystem.x = camera.starSystem.x + xChange
	camera.starSystem.y = camera.starSystem.y + yChange
	camera.x = newX
	camera.y = newY
end

function Camera.update(camera, examining, world, dt)
	if examining then
		Camera.moveCamera(camera, world, examining[1], examining[2])
	elseif camera.followingBody then
		Camera.moveCamera(camera, world, camera.followingBody.x, camera.followingBody.y)
	end
end

function Camera.drawTo(camera, logicX, logicY, drawFunc)
	--drawFunc takes a drawX and drawY, nothing else drawFunc(drawX, drawY)
	local drawX, drawY = Camera.getDrawCoords(logicX, logicY, camera)
	
	love.graphics.setCanvas(camera.canvas)
	drawFunc(drawX, drawY)
	love.graphics.setCanvas()
end

function Camera.draw(x, y, camera)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(camera.canvas, x, y)
end

function Camera.reset(camera)
	love.graphics.setCanvas(camera.canvas)
	love.graphics.clear()
	love.graphics.setCanvas()
end

return Camera