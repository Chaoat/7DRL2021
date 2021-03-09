local Letter = {}

local fontImage = love.graphics.newImage("fonts/font.png")
local quadBank = {}
local letterTileWidth = 12
local letterTileHeight = 12

function doFontPreProcessing()
	fontImage:setFilter("nearest", "nearest")
	
	local addQuadToBank = function(letter, x, y)
		quadBank[letter] = love.graphics.newQuad(1 + (letterTileWidth + 1)*x, 1 + (letterTileHeight + 1)*y, letterTileWidth, letterTileHeight, fontImage:getWidth(), fontImage:getHeight())
	end
	
	for i = 0, 25 do
		addQuadToBank(string.char(65 + i), i%13, math.floor(i/13))
		addQuadToBank(string.char(97 + i), i%13, 2 + math.floor(i/13))
	end
	for i = 0, 9 do
		addQuadToBank(tostring(i), i, 6)
	end
	addQuadToBank("\\", 0, 4)
	addQuadToBank("|", 1, 4)
	addQuadToBank("/", 2, 4)
	addQuadToBank("-", 3, 4)
	addQuadToBank("+", 4, 4)
	addQuadToBank("||", 5, 4)
	addQuadToBank("=", 6, 4)
	
	addQuadToBank(";", 8, 4)
	addQuadToBank(",", 9, 4)
	addQuadToBank(".", 10, 4)
	addQuadToBank("~", 11, 4)
	addQuadToBank("'", 12, 4)
	
	addQuadToBank("@", 0, 5)
	addQuadToBank(" ", 1, 5)
	addQuadToBank("#", 2, 5)
	addQuadToBank(">>", 3, 5)
	addQuadToBank("%", 4, 5)
	addQuadToBank(":", 5, 5)
	addQuadToBank("*", 6, 5)
	addQuadToBank("\"", 7, 5)
	
	addQuadToBank("uA", 0, 7)
	addQuadToBank("urA", 1, 7)
	addQuadToBank("rA", 2, 7)
	addQuadToBank("drA", 3, 7)
	addQuadToBank("dA", 4, 7)
	addQuadToBank("dlA", 5, 7)
	addQuadToBank("lA", 6, 7)
	addQuadToBank("ulA", 7, 7)
end

--Instantiate letter
function Letter.initiateLetter(letter, colour, backColour)
	if not backColour then
		backColour = {0, 0, 0, 0}
	end
	local letter = {letter = letter, colour = colour, backColour = backColour, facing = 0, momentaryInfluenceColour = {0, 0, 0, 0}, momentaryInfluence = 0}
	return letter
end

function Letter.copyLetter(letter)
	local newLetter = initiateLetter(letter.letter, letter.colour)
	return newLetter
end

--Draw a letter at tile[x][y] on camera
function Letter.drawLetter(letter, x, y, camera)
	local actualX = x
	local actualY = y
	if letter.shaking then
		actualX = actualX + randBetween(-letter.shaking, letter.shaking)
		actualY = actualY + randBetween(-letter.shaking, letter.shaking)
	end
	
	if letter.windWave then
		local windX, windY = getWindAtPoint(letter.windWave, x, y)
		actualX = actualX + windX
		actualY = actualY + windY
	end
	
	local drawX, drawY = getDrawPos(actualX, actualY, camera)
	
	if quadBank[letter.letter] == nil then
		error("Letter missing: " .. letter.letter)
	end
	
	if letter.backColour then
		drawBackdrop(letter, x, y, camera)
	end
	
	if letter.momentaryInfluence > 0 then
		love.graphics.setColor(blendColours(letter.momentaryInfluenceColour, letter.colour, letter.momentaryInfluence))
	else
		if letter.colour == nil then
			error("Letter color: " .. letter.letter)
		else
			love.graphics.setColor(letter.colour)
		end
	end
	
	love.graphics.draw(fontImage, quadBank[letter.letter], drawX + camera.tileWidth/2, drawY + camera.tileHeight/2, letter.facing, camera.tileWidth/letterTileWidth, camera.tileHeight/letterTileHeight, letterTileWidth/2, letterTileHeight/2)
end

function Letter.drawBackdrop(letter, x, y, camera)
	local drawX, drawY = getDrawPos(x, y, camera)
	
	if letter.momentaryInfluence > 0 then
		love.graphics.setColor(blendColours(letter.momentaryInfluenceColour, letter.backColour, letter.momentaryInfluence))
	else
		love.graphics.setColor(letter.backColour)
	end
	
	love.graphics.rectangle('fill', drawX, drawY, camera.tileWidth, camera.tileHeight)
end

return Letter