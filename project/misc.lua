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

return Misc