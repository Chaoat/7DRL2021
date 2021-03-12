local InfoScreen = {}

local infoScreenTitle = ""
local infoScreenText = ""
local infoDisplaying = false
local displayTime = 0
function InfoScreen.displayInfoScreen(title, text)
	displayTime = GlobalClock
	infoDisplaying = true
	infoScreenTitle = title
	infoScreenText = text
end

function InfoScreen.closeInfoScreen()
	infoDisplaying = false
end

function InfoScreen.drawInfoScreen(x, y, width, height)
	if infoDisplaying then
		local openingState = math.min(1, (GlobalClock - displayTime)/0.3)
		
		love.graphics.setLineWidth(3)
		
		x = x + (1 - openingState)*(width/2)
		y = y + (1 - openingState)*(height/2)
		
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.rectangle("fill", x, y, openingState*width, openingState*height)
		love.graphics.setColor(0.7, 0.7, 0.7, 1)
		love.graphics.rectangle("line", x, y, openingState*width, openingState*height)
		
		if openingState == 1 then
			Shader.pixelateTextShader:send("threshold", 0.5)
			love.graphics.setShader(Shader.pixelateTextShader)
			
			love.graphics.setColor(1, 1, 1, 1)
			Font.setFont("437", 30)
			love.graphics.printf(infoScreenTitle, x + 5, y + 5, width - 10, "left")
			Font.setFont("437", 16)
			love.graphics.printf(infoScreenText, x + 5, y + 40, width - 10, "left")
			
			love.graphics.printf("[Esc/i to Return]", x + 5, y + height - 20, width - 10, "right")
			
			love.graphics.setShader()
		end
	end
end

function InfoScreen.getDisplaying()
	return infoDisplaying
end

function InfoScreen.drawExamineCursor(game, camera)
	if game.examining then
		love.graphics.setColor(1, 1, 1, 1)
		Image.drawImage(Image.getImage("examineCursor"), camera, game.examining[1], game.examining[2], 0)
	end
end

return InfoScreen