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
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(fIText.text, x - fIText.wrapLimit/2, y)
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
	local fIText = fadeInText(Font.getFont("437", 16), "testststststststststystyststst", 2, 4, {1, 1, 1, 1}, 300, "center")
	
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
	local fIText = fadeInText(Font.getFont("437", 16), "testststststststststystyststst", 2, 4, {1, 1, 1, 1}, 300, "center")
	
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