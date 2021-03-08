local CanvasCache = {}

local canvases = {}
local canvasCounts = {}

local function getKey(width, height)
	return width .. " " .. height
end

function CanvasCache.getCanvas(width, height)
	--Gets a canvas from the canvas cache. Remember to return after use.
	local key = getKey(width, height)
	if canvasCounts[key] and canvasCounts[key] > 0 then
		local canvas = canvases[key][canvasCounts[key]]
		table.remove(canvases[key], canvasCounts[key])
		canvasCounts[key] = canvasCounts[key] - 1
		
		canvas:setFilter('nearest', 'nearest')
		
		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		love.graphics.setCanvas()
		
		return canvas
	else
		local canvas = love.graphics.newCanvas(width, height)
		return canvas
	end
end

local function checkCanvasPresent(canvases, canvas)
	local oldCanvas = love.graphics.getCanvas()
	for i = 1, #canvases do
		love.graphics.setCanvas(canvases[i])
		love.graphics.draw(canvas)
	end
	love.graphics.setCanvas(oldCanvas)
end

function CanvasCache.returnCanvas(canvas)
	--Returns a canvas to the canvas bank. Technically this doesn't even have to be a canvas gotten from the canvas cache.
	local key = getKey(canvas:getWidth(), canvas:getHeight())
	
	if not canvases[key] then
		canvases[key] = {}
		canvasCounts[key] = 0
	end
	--checkCanvasPresent(canvases[key], canvas)
	table.insert(canvases[key], canvas)
	canvasCounts[key] = canvasCounts[key] + 1
end

function CanvasCache.getContentsString()
	--Gets the contents of the canvas cache as a string, useful for debug.
	local returnString = ""
	for key, value in pairs(canvasCounts) do
		returnString = returnString .. key .. ": " .. tostring(value) .. "\n"
	end
	return returnString
end

return CanvasCache