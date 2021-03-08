local Character = {}

function Character.new(body, stepStrength)
	local world = body.world
	local character = {body = body, stepStrength = stepStrength, targetX = body.x, targetY = body.y, world = world}
	
	table.insert(world.characters, character)
	
	return character
end

function Character.update(character, turnTimeLeft, dt)
	local body = character.body
	local targetDistance = math.sqrt((character.targetX - body.x)^2 + (character.targetY - body.y)^2)
	local targetAngle = math.atan2(character.targetY - body.y, character.targetX - body.x)
	
	local targetSpeed = targetDistance/turnTimeLeft
	local speedTo, angleTo = PhysicsSystem.findVectorBetween(body.speed, body.angle, targetSpeed, targetAngle)
	
	Body.impartForce(body, math.min(speedTo, character.stepStrength*dt)*body.mass, angleTo)
end

function Character.moveCharacter(character, x, y)
	character.targetX = Misc.round(character.body.x + x)
	character.targetY = Misc.round(character.body.y + y)
end

return Character