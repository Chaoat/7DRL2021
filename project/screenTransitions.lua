local ScreenTransitions = {}

local function updateFadeInText(fIText, timer)
	local percentDone = math.min((timer - fIText.startPoint)/fIText.duration, 1)
	if percentDone > 0 then
		local nFullLetters = math.floor(percentDone*fIText.stringLength)
		
		local colouredText = {string.sub(fIText.fullString, 1, nFullLetters), fIText.colour}
		
		if percentDone < 1 then
			table.insert(colouredText, string.sub(fIText.fullString, nFullLetters + 1, nFullLetters + 1))
			local timePerLetter = fIText.stringLength/fIText.duration
			local alpha = (percentDone*fIText.stringLength - nFullLetters)/timePerLetter
			table.insert(colouredText, {fIText.colour[1], fIText.colour[2], fIText.colour[3], alpha})
		end
		
		fIText.text:setf(colouredText, fIText.wrapLimit, fIText.alignmode)
	end
end
local function drawFadeInText(x, y, fIText)
	if fIText.text:getWidth() > 0 and fIText.text:getHeight() > 0 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(fIText.text, x - fIText.wrapLimit/2, y)
		love.graphics.setShader(Shader.glow)
		Shader.glow:send("glowSize", 1)
		Shader.glow:send("innerColour", {0, 0, 0, 1})
		Shader.glow:send("outerColour", {0, 0, 0, 1})
		Shader.glow:send("borderColour", {0, 0, 0, 1})
		Shader.glow:send("borderSize", 1)
		Shader.glow:send("imageDimensions", {fIText.text:getWidth(), fIText.text:getHeight()})
		love.graphics.draw(fIText.text, x - fIText.wrapLimit/2, y)
		love.graphics.setShader()
	end
end
local function fadeInText(font, str, startPoint, duration, colour, wrapLimit, alignmode)
	local text = love.graphics.newText(font, nil)
	
	local fIText = {text = text, startPoint = startPoint, duration = duration, fullString = str, stringLength = #str, colour = colour, wrapLimit = wrapLimit, alignmode = alignmode}
	return fIText
end

function ScreenTransitions.fadeToBlack(fadeInTime, waitTime, fadeOutTime)
	local transition
	local timer = 0
	local alpha = 0
	
	local drawFunc = function()
		love.graphics.setColor(0, 0, 0, alpha)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end
	
	local updateFunc = function(dt)
		timer = timer + dt
		if timer < fadeInTime then
			alpha = timer/fadeInTime
		elseif timer < fadeInTime + waitTime then
			alpha = 1
		elseif timer < fadeInTime + waitTime + fadeOutTime then
			alpha = 1 - (timer - fadeInTime - waitTime)/fadeOutTime
		else
			transition.over = true
		end
	end
	
	transition = {drawFunc = drawFunc, updateFunc = updateFunc}
	return transition
end

function ScreenTransitions.die()
	local transition
	local timer = 0
	local red = 1
	local fIText = fadeInText(Font.getFont("437", 16), "It is over, your body destroyed and your soul departed, your struggle ended.\n\nPress R to rewind the clock", 2, 5, {1, 1, 1, 1}, 300, "center")
	
	local drawFunc = function()
		local colour = Misc.blendColours({0, 0, 0, 0.2}, {0.6, 0.1, 0.05, 0.8}, red)
		love.graphics.setColor(colour)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		drawFadeInText(love.graphics.getWidth()/2, 100, fIText)
	end
	
	local updateFunc = function(dt)
		timer = timer + dt
		
		updateFadeInText(fIText, timer)
		
		red = math.max(1 - timer, 0)
	end
	
	transition = {drawFunc = drawFunc, updateFunc = updateFunc}
	return transition
end

function ScreenTransitions.win()
	local transition
	local timer = 0
	local red = 1
	local fIText = fadeInText(Font.getFont("437", 16), "As your soul leaves your body, consumed by the shackle to renew itself, you experience for a moment a complete awareness of the Labyrinth and that contained within. It is as if you and the structure are becoming one, and gradually you become aware of beings surrounding you. The closest are clearly the previous runners, you recognise their faces, immortalised by the greatest artists of your people, but there are more further down the chain. In the distance you can just make out the smudged blurs of the original creators, outlined against a colossal shape towering over the Labyrinth, dwarfing even the sun with its size. A smile touches your lips as you realise who this must be, for a look of rage covers his enormous face, and his mouth is open in a silent frustrated scream.\n\nYour people are safe for another millenium.", 2, 15, {1, 1, 1, 1}, 500, "center")
	
	local drawFunc = function()
		local colour = Misc.blendColours({0, 0, 0, 0.2}, {1, 1, 1, 0.8}, red)
		love.graphics.setColor(colour)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		drawFadeInText(love.graphics.getWidth()/2, 100, fIText)
	end
	
	local updateFunc = function(dt)
		timer = timer + dt
		
		updateFadeInText(fIText, timer)
		
		red = math.max(1 - timer, 0)
	end
	
	transition = {drawFunc = drawFunc, updateFunc = updateFunc}
	return transition
end

return ScreenTransitions