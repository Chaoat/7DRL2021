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

function Misc.binaryInsert(list, element, comparitor)
	local elementWeight = element[comparitor]
	
	local first = 1
	local last = #list
	while first <= last do
		local i = math.ceil((last + first)/2)
		if list[i][comparitor] <= elementWeight then
			first = i + 1
		elseif list[i][comparitor] > elementWeight then
			last = i - 1
		end
	end
	table.insert(list, first, element)
	
	
	return first
end

function Misc.blendColours(colour1, colour2, ratio)
	local rInverse = 1 - ratio
	return {colour1[1]*rInverse + colour2[1]*ratio, colour1[2]*rInverse + colour2[2]*ratio, colour1[3]*rInverse + colour2[3]*ratio, colour1[4]*rInverse + colour2[4]*ratio}
end

function Misc.addColours(colour, addedColour)
	local ratio = colour[4]/(colour[4] + addedColour[4])
	colour[1] = colour[1]*ratio + addedColour[1]*(1 - ratio)
	colour[2] = colour[2]*ratio + addedColour[2]*(1 - ratio)
	colour[3] = colour[3]*ratio + addedColour[3]*(1 - ratio)
	colour[4] = math.min(colour[4] + addedColour[4], 1)
end

return Misc