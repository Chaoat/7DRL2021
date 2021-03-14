local Sound = {}

local sounds = {}

function Sound.newSound(name, volume)
	if not sounds[name] then
		sounds[name] = love.audio.newSource("sounds/" .. name, "static")
	end
	
	local newSound = sounds[name]:clone()
	newSound:setVolume(volume)
	return newSound
end

function Sound.singlePlaySound(name, volume)
	local sound = Sound.newSound(name, volume)
	sound:seek(0)
	sound:stop()
	sound:play()
end

return Sound