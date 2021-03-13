local Stars = {}

function Stars.newStarSystem(camera)
	stars = {}
	
	local nStars = math.ceil((camera.canvasDims[1]*camera.canvasDims[2])/1000)
	for i = 1, nStars do
		table.insert(stars, {x = math.random()*2000, y = math.random()*2000, distance = 0.7*math.random()})
	end
	
	local starSystem = {stars = stars, x = 0, y = 0}
	return starSystem
end

function Stars.draw(x, y, starSystem, camera)
	for i = 1, #starSystem.stars do
		local star = starSystem.stars[i]
		love.graphics.setColor(1, 1, 1, 1*star.distance)
		local drawX = star.x - starSystem.x*star.distance
		local drawY = star.y - starSystem.y*star.distance
		
		while drawX > camera.canvasDims[1] or drawX < 0 do
			if drawX > camera.canvasDims[1] then
				drawX = drawX - camera.canvasDims[1]
			else
				drawX = drawX + camera.canvasDims[1]
			end
		end
		
		while drawY > camera.canvasDims[2] or drawY < 0 do
			if drawY > camera.canvasDims[2] then
				drawY = drawY - camera.canvasDims[2]
			else
				drawY = drawY + camera.canvasDims[2]
			end
		end
		
		love.graphics.points(drawX + x, drawY + y)
	end
end

return Stars