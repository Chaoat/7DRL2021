local Sound = {}

local sounds = {}

local maxSoundDist = 30
local soundCenter = {0, 0}

function Sound.setCenter(x, y)
	soundCenter = {x, y}
end

function Sound.newSound(name, volume)
	if not sounds[name] then
		sounds[name] = love.audio.newSource("sounds/" .. name, "static")
	end
	
	local newSound = sounds[name]:clone()
	newSound:setVolume(volume)
	return newSound
end

function Sound.loopPlayerSound(name, volume, posX, posY)
	local dist = math.sqrt((posX - soundCenter[1])^2 + (posY - soundCenter[2])^2)
	if dist <= maxSoundDist then
		local mod = 1 - dist/maxSoundDist
		local sound = Sound.newSound(name, mod*volume)
		sound:setLooping(true)
		sound:seek(0)
		sound:stop()
		sound:play()
		return {sound, volume}
	end
	return false
end

function Sound.updateVolume(loopSound, newX, newY)
	local dist = math.sqrt((newX - soundCenter[1])^2 + (newY - soundCenter[2])^2)
	if dist <= maxSoundDist then
		local mod = 1 - dist/maxSoundDist
		loopSound[1]:setVolume(loopSound[2]*mod)
	end
end

function Sound.singlePlaySound(name, volume, posX, posY)
	local dist = math.sqrt((posX - soundCenter[1])^2 + (posY - soundCenter[2])^2)
	if dist <= maxSoundDist then
		local mod = 1 - dist/maxSoundDist
		local sound = Sound.newSound(name, mod*volume)
		sound:seek(0)
		sound:stop()
		sound:play()
	end
end

return Sound