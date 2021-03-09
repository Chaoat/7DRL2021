local Random = {}

function Random.pointOnCircle(x, y, angleRange, distanceRange)
	local angle = angleRange[1] + math.random()*(angleRange[2] - angleRange[1])
	
	local power = 0.5 + distanceRange[1]/distanceRange[2]
	local distance = distanceRange[1] + math.pow(math.random(), power)*(distanceRange[2] - distanceRange[1])
	return x + math.cos(angle)*distance, y + math.sin(angle)*distance
end

function Random.randomPointInRegion(x, y, width, height)
	local returnX = x + (math.random() - 0.5)*width
	local returnY = y + (math.random() - 0.5)*height
	return returnX, returnY
end

function Random.randomBetweenPoints(a, b)
	return math.random()*(b - a) + a
end

function Random.randomPointRangeBetween(range1, range2, n)
	local angleSegment = (range2 - range1)/n
	
	local angles = {}
	for i = 1, n do
		local angle = range1 + angleSegment*(i - 0.5) + Random.randomBetweenPoints(-angleSegment/2, angleSegment/2)
		table.insert(angles, angle)
	end
	return angles
end

function Random.nRandomFromList(list, n)
	if n > #list then
		n = #list
	end
	
	local tInsert = table.insert
	
	local indices = {}
	for i = 1, #list do
		tInsert(indices, i)
	end
	
	local entries = {}
	local chosenIndices = {}
	while n > 0 do
		local i = math.ceil(math.random()*#indices)
		tInsert(chosenIndices, i)
		tInsert(entries, list[indices[i]])
		table.remove(indices, i)
		n = n - 1
	end
	
	return entries, chosenIndices
end

function Random.randomFromList(list)
	local entries, chosenIndices = Random.nRandomFromList(list, 1)
	return entries[1], chosenIndices[1]
end

function Random.randomizeListOrder(list)
	return Random.nRandomFromList(list, #list)
end

function Random.randomColourBetween(colour1, colour2)
	if colour2 == nil then
		return colour1
	end
	
	local colPercent = math.random()
	local r = colour1[1] + colPercent*(colour2[1] - colour1[1])
	local g = colour1[2] + colPercent*(colour2[2] - colour1[2])
	local b = colour1[3] + colPercent*(colour2[3] - colour1[3])
	local a = colour1[4] + colPercent*(colour2[4] - colour1[4])
	
	return {r, g, b, a}
end

function Random.percentChance(percent)
	return math.random() < percent
end

function Random.fromListWithOdds(list, odds)
	local totalOdds = 0
	for i = 1, #odds do
		totalOdds = totalOdds + odds[i]
	end
	
	local rand = math.random()
	for i = 1, #list do
		rand = rand - odds[i]/totalOdds
		if rand < 0 then
			return list[i], i
		end
	end
end

return Random