local Font = {}

local fonts = {}

function Font.setFont(fontName, fontSize)
	if not fonts[fontName] then
		fonts[fontName] = {}
	end
	
	if not fonts[fontName][fontSize] then
		fonts[fontName][fontSize] = love.graphics.newFont("fonts/" .. fontName .. ".ttf", fontSize)
	end
	love.graphics.setFont(fonts[fontName][fontSize])
end

return Font