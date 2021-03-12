local Image = {}

local images = {}
local function loadImage(dir)
	if not images[dir] then
		local path = "sprites/" .. dir .. ".png"
		if love.filesystem.getInfo(path) == nil then
			return nil
		end
	
		local image = {}
		image.image = love.graphics.newImage(path)
		image.width = image.image:getWidth()
		image.height = image.image:getHeight()
		
		image.image:setFilter('nearest', 'nearest')
		
		images[dir] = image
	end
end

function Image.getImage(dir)
	loadImage(dir)
	
	return images[dir]
end

function Image.cleanUpImage(image)
	CanvasCache.returnCanvas(image.image)
end

function Image.canvasToImage(canvas)
	local width = canvas:getWidth()
	local height = canvas:getHeight()
	local newCanvas = CanvasCache.getCanvas(width, height)
	love.graphics.setCanvas(newCanvas)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvas)
	love.graphics.setCanvas()
	return {image = newCanvas, width = width, height = height}
end

function Image.letterToImage(letter, colour)
	local width = GlobalTileDims[1]
	local height = GlobalTileDims[2]
	
	Font.setFont("437", 1.5*height)
	
	width = width + 6
	height = height + 6
	
	local canvas = CanvasCache.getCanvas(width, height)
	canvas:setFilter('nearest', 'nearest')
	love.graphics.setCanvas(canvas)
	love.graphics.setColor(colour)
	
	Shader.pixelateTextShader:send("threshold", 0.5)
	love.graphics.setShader(Shader.pixelateTextShader)
	love.graphics.printf(letter, 3, 3 - 0.2*height, 1.1*width, "center")
	love.graphics.setShader()
	
	love.graphics.setCanvas()
	
	return {image = canvas, width = width, height = height}
end

function Image.drawImage(image, camera, x, y, r)
	Camera.drawTo(camera, x, y, function(drawX, drawY)
		love.graphics.draw(image.image, drawX, drawY, r, 1, 1, image.width/2, image.height/2)
	end)
end

function Image.drawImageWithOutline(image, camera, x, y, r, outlineColour, glowSize)
	Camera.drawTo(camera, x, y, function(drawX, drawY)
		love.graphics.draw(image.image, drawX, drawY, r, 1, 1, image.width/2, image.height/2)
		
		love.graphics.setShader(Shader.glow)
		Shader.glow:send("glowSize", glowSize)
		Shader.glow:send("innerColour", outlineColour)
		Shader.glow:send("outerColour", {outlineColour[1], outlineColour[2], outlineColour[3], 0})
		Shader.glow:send("borderColour", outlineColour)
		Shader.glow:send("borderSize", 1)
		Shader.glow:send("imageDimensions", {image.width, image.height})
		love.graphics.draw(image.image, drawX, drawY, r, 1, 1, image.width/2, image.height/2)
		love.graphics.setShader()
	end)
end

return Image