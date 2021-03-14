local Sound = {}

local sounds = {}

function Sound.newSound(name)
	if not sounds[name] then
		sounds[name] = love.audio.newSource("sounds/" .. name .. ".ogg", "static")
	end
	
	return sounds[name]:clone()
end

function Sound.singlePlaySound(name)
	local sound = Sound.newSound(name)
	sound:seek(0)
	sound:stop()
	sound:play()
end

return Sound