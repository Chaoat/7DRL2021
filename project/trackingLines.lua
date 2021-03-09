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
	return points
end

function TrackingLines.new(x, y, angle, bodyTemplate, simulationTime, world)
	local body = Body.duplicateRaw(bodyTemplate)
	local xOff, yOff = Misc.angleToDir(angle)
	Body.placeInWorld(body, x + xOff, y + yOff, world)
	body.angle = angle
	
	local points = simulate(body, simulationTime)
	local line = {points = points, simulationTime = simulationTime, bodyTemplate = bodyTemplate, body = body}
	table.insert(world.trackingLines, line)
	return line
end

function TrackingLines.updatePoints(line, newX, newY, newAngle)
	local body = Body.duplicateRaw(line.bodyTemplate)
	local xOff, yOff = Misc.angleToDir(newAngle)
	Body.placeInWorld(body, newX + xOff, newY + yOff, line.body.world)
	body.angle = newAngle
	
	local points = simulate(body, line.simulationTime)
	line.points = points
	line.body = body
	return line
end

function TrackingLines.drawAll(trackingLines, camera)
	local i = #trackingLines
	while i > 0 do
		local line = trackingLines[i]
		for j = 1, #line.points do
			local point = line.points[j]
			local tile = Map.getTile(line.body.map, point[1], point[2])
			
			if tile.visible then
				local lightRatio = 2*math.max(((j*line.simulationTime/#line.points - GlobalClock)%(3*GlobalTurnTime)/GlobalTurnTime) - 2.5, 0)
				
				Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
					love.graphics.setColor({1, lightRatio, lightRatio, 0.4 + 0.6*lightRatio})
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

return TrackingLines