local TrackingLines = {}

local function simulate(body, simulationTime)
	simulationTime = math.min(body.duration or simulationTime, simulationTime)
	local points = {{body.x, body.y}}
	if body.speed > 0 then
		local stepSize = 1/body.speed
		while simulationTime > 0 do
			local step = math.min(stepSize, simulationTime)
			Body.update(body, step, true)
			if body.destroy then
				break
			end
			table.insert(points, {body.x, body.y})
			simulationTime = simulationTime - step
		end
	else
		points = {}
	end
	Body.destroy(body)
	return points
end

function TrackingLines.new(x, y, targetX, targetY, bodyTemplate, simulationTime, colour, world)
	local line = {points = nil, simulationTime = simulationTime, bodyTemplate = bodyTemplate, body = nil, colour = colour, world = world}
	TrackingLines.updatePoints(line, x, y, targetX, targetY)
	table.insert(world.trackingLines, line)
	return line
end

function TrackingLines.changeSpeed(line, newSpeed)
	line.bodyTemplate.speed = newSpeed
end

function TrackingLines.updatePoints(line, newX, newY, targetX, targetY)
	local angle = math.atan2(targetY - newY, targetX - newX)
	local body = Body.duplicateRaw(line.bodyTemplate)
	line.body = body
	local xOff, yOff = Misc.angleToDir(angle)
	Body.placeInWorld(body, newX + xOff, newY + yOff, line.world)
	body.angle = angle
	body.simulation = true
	
	if body.preciseLanding and not body.duration then
		local dist = math.sqrt((targetY - newY)^2 + (targetX - newX)^2)
		body.duration = (dist - 2)/body.speed
	end
	
	local points = simulate(body, line.simulationTime)
	line.points = points
	return line
end

function TrackingLines.singlePoint(line, point)
	line.points = {point}
end

function TrackingLines.lineBetween(line, origin, target)
	line.points = Misc.plotLine(origin[1], origin[2], target[1], target[2])
end

function TrackingLines.clear(line)
	line.points = {}
end

function TrackingLines.drawAll(trackingLines, camera)
	local i = #trackingLines
	while i > 0 do
		local line = trackingLines[i]
		if line.destroy then
			table.remove(trackingLines, i)
		else
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