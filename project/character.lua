local Character = {}

function Character.new(body, stepStrength, image)
	local world = body.world
	local character = {body = body, stepStrength = stepStrength, image = image, targetX = body.x, targetY = body.y, world = world, lostFooting = false, parent = false}
	body.parent = character
	character.trackingLine = TrackingLines.new(body.x, body.y, body.x, body.y, body, GlobalTurnTime, {1, 1, 0, 0.4}, world)
	TrackingLines.clear(character.trackingLine)
	character.body.friction = 1
	
	table.insert(world.characters, character)
	
	return character
end

function Character.update(character, turnTimeLeft, dt)
	if not character.lostFooting then
		local body = character.body
		local targetDistance = math.sqrt((character.targetX - body.x)^2 + (character.targetY - body.y)^2)
		local targetAngle = math.atan2(character.targetY - body.y, character.targetX - body.x)
		
		local targetSpeed = targetDistance/turnTimeLeft
		local speedTo, angleTo = PhysicsSystem.findVectorBetween(body.speed, body.angle, targetSpeed, targetAngle)
		
		Body.impartForce(body, math.min(speedTo, character.stepStrength*dt)*body.mass, angleTo)
		
		if not character.flying and (not character.body.tile.floored or character.body.speed > character.stepStrength/5) then
			character.lostFooting = true
		end
	elseif character.body.tile.floored and character.body.speed <= character.stepStrength/5 then
		character.lostFooting = false
		character.targetX = Misc.round(character.body.x)
		character.targetY = Misc.round(character.body.y)
	end
end

function Character.updateCharacterTrackingLines(characters)
	for i = 1, #characters do
		local character = characters[i]
		if character.body.destroy then
			character.trackingLine.destroy = true
		else
			if character.lostFooting then
				TrackingLines.changeSpeed(character.trackingLine, character.body.speed)
				local xOff, yOff = Misc.angleToOffset(character.body.angle, 1)
				TrackingLines.updatePoints(character.trackingLine, character.body.x, character.body.y, character.body.x + xOff, character.body.y + yOff)
			elseif character.targetX ~= character.body.tile.x or character.targetY ~= character.body.tile.y then
				TrackingLines.lineBetween(character.trackingLine, {character.body.x, character.body.y}, {character.targetX, character.targetY})
			else
				TrackingLines.clear(character.trackingLine)
			end
		end
	end
end

function Character.moveCharacter(character, x, y)
	character.targetX = Misc.round(character.body.x + x)
	character.targetY = Misc.round(character.body.y + y)
end

function Character.drawCharacters(characters, camera)
	for i = 1, #characters do
		local character = characters[i]
		local tile = Map.getTile(character.body.map, character.body.x, character.body.y)
		if tile.visible then
			if character.body.destroy then
				love.graphics.setColor(0.3, 0.3, 0.3, 1)
			else
				TileColour.drawColourOnTile({0.5, 0.5, 0, 0.2}, tile, camera)
				
				love.graphics.setColor(1, 1, 1, 1)
			end
			Image.drawImage(character.image, camera, character.body.x, character.body.y, 0)
			
			local body = character.body
			if body.health < body.maxHealth and not body.destroy then
				Camera.drawTo(camera, body.x, body.y, function(drawX, drawY)
					love.graphics.setColor(1, 0, 0, 1)
					love.graphics.setLineStyle("rough")
					love.graphics.setLineWidth(2)
					love.graphics.circle("line", drawX, drawY, 11)
					
					love.graphics.setColor(0, 1, 0, 1)
					love.graphics.arc("line", "open", drawX, drawY, 11, -math.pi/2, -math.pi/2 - (body.health/body.maxHealth)*(2*math.pi), 10)
				end)
			end
		end
	end
end

return Character