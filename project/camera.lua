local Camera = {}

function Camera.new(cameraWidth, cameraHeight, tileWidth, tileHeight)
	local canvas = CanvasCache.getCanvas(cameraWidth, cameraHeight)
	local camera = {x = 0, y = 0, canvas = canvas, canvasDims = {cameraWidth, cameraHeight}, tileDims = {tileWidth, tileHeight}, followingBody = nil}
	return camera
end

function Camera.getDrawCoords(logicX, logicY, camera)
	local drawX = (logicX - camera.x)*camera.tileDims[1] + camera.canvasDims[1]/2
	local drawY = (logicY - camera.y)*camera.tileDims[2] + camera.canvasDims[2]/2
	return drawX, drawY
end

function Camera.update(camera, dt)
	if camera.followingBody then
		camera.x = camera.followingBody.x
		camera.y = camera.followingBody.y
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