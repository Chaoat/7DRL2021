local Character = {}

function Character.new(body, stepStrength, image)
	local world = body.world
	local character = {body = body, stepStrength = stepStrength, image = image, targetX = body.x, targetY = body.y, world = world, lostFooting = false}
	
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
		
		if not character.body.tile.floored or character.body.speed > character.stepStrength/5 then
			character.lostFooting = true
		end
	elseif character.body.tile.floored and character.body.speed <= character.stepStrength/5 then
		character.lostFooting = false
	end
end

function Character.moveCharacter(character, x, y)
	character.targetX = Misc.round(character.body.x + x)
	character.targetY = Misc.round(character.body.y + y)
end

function Character.drawCharacters(characters, camera)
	for i = 1, #characters do
		local character = characters[i]
		love.graphics.setColor(1, 1, 1, 1)
		Image.drawImage(character.image, camera, character.body.x, character.body.y, 0)
	end
end

return Character