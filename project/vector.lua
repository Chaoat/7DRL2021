local Vector = {}

function Vector.magAngleToVec(mag, angle)
	return mag*math.cos(angle), mag*math.sin(angle)
end

function Vector.vecToMagAngle(x, y)
	return math.sqrt(x^2 + y^2), math.atan2(y, x)
end

function Vector.addVectors(speed1, angle1, speed2, angle2)
	local nXSpeed = speed1*math.cos(angle1) + speed2*math.cos(angle2)
	local nYSpeed = speed1*math.sin(angle1) + speed2*math.sin(angle2)
	local nSpeed = math.sqrt(nXSpeed^2 + nYSpeed^2)
	local nAngle = math.atan2(nYSpeed, nXSpeed)
	return nSpeed, nAngle
end

function PhysicsSystem.findVectorBetween(speedF, angleF, speedT, angleT)
	local fX, fY = Vector.magAngleToVec(speedF, angleF)
	local tX, tY = Vector.magAngleToVec(speedT, angleT)
	return Vector.vecToMagAngle(tX - fX, tY - fY)
end

function PhysicsSystem.findVectorInAngle(speed, angle, incidentAngle)
	angle = Misc.simplifyAngle(angle - incidentAngle)
	speedInAngle = speed*math.cos(angle)
	return speedInAngle
end

return Vector