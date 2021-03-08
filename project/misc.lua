local Misc = {}

function Misc.round(n)
	return math.floor(n + 0.5)
end

function Misc.simplifyAngle(a)
	return (a + math.pi)%(2*math.pi) - math.pi
end

function Misc.distBetweenAngles(a1, a2)
	local difference = math.abs(Misc.simplifyAngle(a2 - a1))
	
	return math.min(difference, 2*math.pi - difference)
end

function Misc.angleToDir(angle)
	angle = Misc.simplifyAngle(angle)
	
	local x = 0
	if angle >= -3*math.pi/8 and angle < 3*math.pi/8 then
		x = 1
	elseif angle >= 5*math.pi/8 or angle < -5*math.pi/8 then
		x = -1
	end
	
	local y = 0
	if angle >= math.pi/8 and angle < 7*math.pi/8 then
		y = 1
	elseif angle >= -7*math.pi/8 and angle < -math.pi/8 then
		y = -1
	end
	
	return x, y
end

return Misc