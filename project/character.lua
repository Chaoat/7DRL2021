local Character = {}

function Character.new(body, stepStrength, image, name, text)
	if not name then
		name = "placeholder"
	end
	if not text then
		text = "placeholder"
	end
	
	local world = body.world
	local character = {body = body, stepStrength = stepStrength, image = image, targetX = body.x, targetY = body.y, world = world, lostFooting = false, parent = false, name = name, text = text}
	body.parent = character
	character.trackingLine = TrackingLines.new(body.x, body.y, body.x, body.y, body, GlobalTurnTime, {1, 1, 0, 0.4}, world)
	TrackingLines.clear(character.trackingLine)
	character.body.friction = 1
	
	table.insert(world.characters, character)
	
	return character
end

function Character.update(character, turnTimeLeft, dt)
	if character.stepStrength > 0 then
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
	else
		character.lostFooting = true
		character.targetX = character.body.x
		character.targetY = character.body.y
	end
end

function Character.updateCharacterTrackingLines(characters)
	for i = 1, #characters do
		local character = characters[i]
		
		if character.body.destroy then
			character.trackingLine.destroy = true
		else
			if character.stepStrength > 0 then
				if character.lostFooting or character.flying then
					TrackingLines.changeSpeed(character.trackingLine, character.body.speed)
					local xOff, yOff = Misc.angleToOffset(character.body.angle, 1)
					TrackingLines.updatePoints(character.trackingLine, character.body.x, character.body.y, character.body.x + xOff, character.body.y + yOff)
				elseif character.targetX ~= character.body.tile.x or character.targetY ~= character.body.tile.y then
					TrackingLines.lineBetween(character.trackingLine, {character.body.x, character.body.y}, {character.targetX, character.targetY})
				else
					TrackingLines.clear(character.trackingLine)
				end
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

function Character.clearCharacters(characters, parentList)
	for i = 1, #parentList do
		parentList[i].character.destroy = true
	end
	
	local i = #characters
	while i > 0 do
		local character = characters[i]
		if character.destroy then
			local body = character.body
			body.destroy = true
			Map.addTileToCleanQueue(body.map, body.tile, body.layer)
			Map.cleanAllTiles(body.map)
			character.trackingLine.destroy = true
			table.remove(characters, i)
		end
		i = i - 1
	end
end

function Character.drawCharacters(characters, camera)
	for i = 1, #characters do
		local character = characters[i]
		local tile = Map.getTile(character.body.map, character.body.x, character.body.y)
		if tile.visible then
			if character.body.destroy then
				love.graphics.setColor(0.3, 0.3, 0.3, 1)
				Image.drawImage(character.image, camera, character.body.x, character.body.y, 0)
			else
				if globalGame.examining then
					local flash = 2*((GlobalClock%1) - 0.5)
					TileColour.drawColourOnTile({0.5 + flash, 0.5 + flash, flash, 0.5 + flash}, tile, camera)
				else
					TileColour.drawColourOnTile({0.5, 0.5, 0, 0.5}, tile, camera)
				end
				
				if character.parent and character.parent.firing then
					local brightness = Misc.oscillateBetween(0, 1, 0.2)
					love.graphics.setColor(brightness, brightness, brightness, 1)
					love.graphics.setShader(Shader.colourAdd)
				else
					love.graphics.setColor(1, 1, 1, 1)
				end
				Image.drawImageWithOutline(character.image, camera, character.body.x, character.body.y, 0, {0, 0, 0, 1}, 2)
			end
			
			love.graphics.setShader()
			
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