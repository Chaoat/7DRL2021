local TrackingLines = {}

local function simulate(body, simulationTime)
	local points = {{body.x, body.y}}
	local stepSize = 1/body.speed
	while simulationTime > 0 do
		local step = stepSize
		Body.update(body, step, true)
		if body.destroy then
			break
		end
		table.insert(points, {body.x, body.y})
		simulationTime = simulationTime - step
	end
	Body.destroy(body)
	return points
end

function TrackingLines.new(x, y, angle, bodyTemplate, simulationTime, colour, world)
	local body = Body.duplicateRaw(bodyTemplate)
	local xOff, yOff = Misc.angleToDir(angle)
	Body.placeInWorld(body, x + xOff, y + yOff, world)
	body.angle = angle
	body.simulation = true
	
	local points = simulate(body, simulationTime)
	local line = {points = points, simulationTime = simulationTime, bodyTemplate = bodyTemplate, body = body, colour = colour}
	table.insert(world.trackingLines, line)
	return line
end

function TrackingLines.changeSpeed(line, newSpeed)
	line.bodyTemplate.speed = newSpeed
end

function TrackingLines.updatePoints(line, newX, newY, newAngle)
	local body = Body.duplicateRaw(line.bodyTemplate)
	local xOff, yOff = Misc.angleToDir(newAngle)
	Body.placeInWorld(body, newX + xOff, newY + yOff, line.body.world)
	body.angle = newAngle
	body.simulation = true
	
	local points = simulate(body, line.simulationTime)
	line.points = points
	line.body = body
	return line
end

function TrackingLines.singlePoint(line, point)
	line.points = {point}
end

function TrackingLines.clear(line)
	line.points = {}
end

function TrackingLines.drawAll(trackingLines, camera)
	local i = #trackingLines
	while i > 0 do
		local line = trackingLines[i]
		for j = 1, #line.points do
			local point = line.points[j]
			local tile = Map.getTile(line.body.map, point[1], point[2])
			
			if tile.visible then
				local lightRatio = (2*math.max(((j*line.simulationTime/#line.points - GlobalClock)%(3*GlobalTurnTime)/GlobalTurnTime) - 2.5, 0))
				
				local colour = Misc.blendColours(line.colour, {1, 1, 1, 1}, lightRatio)
				Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
					love.graphics.setColor(colour)
					love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
				end)
			end
		end
		
		if line.destroy then
			table.remove(trackingLines, i)
		end
		i = i - 1
	end
end

function TrackingLines.findIntercept(x, y, speed, tCharacter)
	local tBody = tCharacter.body
	local dist = math.sqrt((tBody.y - y)^2 + (tBody.x - x)^2)
	local timeBetween = dist/speed
	
	if #tCharacter.trackingLine.points == 0 then
		return {tBody.x, tBody.y}
	else
		if timeBetween <= GlobalTurnTime then
			local pointIndex = math.ceil((timeBetween/GlobalTurnTime)*#tCharacter.trackingLine.points)
			return tCharacter.trackingLine.points[pointIndex]
		else
			local tBodyMovement = tBody.speed*timeBetween
			local targetX = tBody.x + tBodyMovement*math.cos(tBody.angle)
			local targetY = tBody.y + tBodyMovement*math.sin(tBody.angle)
			return {Misc.round(targetX), Misc.round(targetY)}
		end
	end
end

return TrackingLines