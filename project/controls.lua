local Controls = {}

local controlsEnabled = {}
local controlTable = {}
local inverseControlTable = {}
local function addControl(key, control)
	if not controlTable[key] then
		controlTable[key] = {}
	end
	controlTable[key][control] = true
	
	if not controlsEnabled[control] then
		controlsEnabled[control] = true
	end
	
	if not inverseControlTable[control] then
		inverseControlTable[control] = {}
	end
	table.insert(inverseControlTable[control], key)
end

local function addControls(control, keys)
	for i = 1, #keys do
		addControl(keys[i], control)
	end
end

--addControls("turnEnd", {"space"})

addControls("topLeft", {"kp7", "q"})
addControls("top", {"kp8", "w"})
addControls("topRight", {"kp9", "e"})
addControls("left", {"kp4", "a"})
addControls("center", {"kp5", "s"})
addControls("right", {"kp6", "d"})
addControls("botLeft", {"kp1", "z"})
addControls("bot", {"kp2", "x"})
addControls("botRight", {"kp3", "c"})

addControls("weapon1", {"1"})
addControls("weapon2", {"2"})
addControls("weapon3", {"3"})
addControls("weapon4", {"4"})
addControls("weapon5", {"5"})
addControls("weapon6", {"6"})
addControls("weapon7", {"7"})
addControls("weapon8", {"8"})
addControls("weapon9", {"9"})
addControls("weapon10", {"0"})

addControls("return", {"escape", "i"})
addControls("examine", {"i"})
addControls("cycleTargets", {"tab", "t"})

addControls("chainFire", {"lshift"})

function Controls.keyToControls(key)
	--Returns the controls attached to a certain key
	local list = {}
	if controlTable[key] then
		for control, value in pairs(controlTable[key]) do
			if controlsEnabled[control] then
				list[control] = true
			end
		end
	end
	return list
end

function Controls.checkControl(key, control)
	--Checks whether a certain key activates a certain control
	if not controlsEnabled[control] then
		return false
	end
	
	local list = {}
	if controlTable[key] then
		list = controlTable[key]
	end
	return list[control]
end

function Controls.checkControlHeld(control)
	for i = 1, #inverseControlTable[control] do
		local key = inverseControlTable[control][i]
		if love.keyboard.isDown(key) then
			return true
		end
	end
	return false
end

function Controls.enableControl(control, enabled)
	controlsEnabled[control] = enabled
end

function Controls.checkControlEnabled(control)
	return controlsEnabled[control]
end

function Controls.enableAllControls(enabled)
	for control, enabled in pairs(controlsEnabled) do
		controlsEnabled[control] = enabled
	end
end

function Controls.drawButton(x, y, control, availableFunction)
	local key = inverseControlTable[control][1]
	
	local pressed = love.keyboard.isDown(key)
	local unAvailable = not Controls.checkControlEnabled(control)
	if availableFunction then
		unAvailable = unAvailable or not availableFunction()
	end
	
	local keyImage = Image.getImage("interface/buttons/letters/" .. key)
	if pressed then
		love.graphics.draw(keyImage.image, x, y + 1, 0, 1, 1, keyImage.width/2, keyImage.height/2)
	else
		love.graphics.draw(keyImage.image, x, y - 2, 0, 1, 1, keyImage.width/2, keyImage.height/2)
	end
	
	local buttonImage = Image.getImage("interface/buttons/unPressed")
	if pressed and unAvailable then
		buttonImage = Image.getImage("interface/buttons/pressedUnAvailable")
	elseif pressed then
		buttonImage = Image.getImage("interface/buttons/pressed")
	elseif unAvailable then
		buttonImage = Image.getImage("interface/buttons/unAvailable")
	end
	love.graphics.draw(buttonImage.image, x, y, 0, 1, 1, buttonImage.width/2, buttonImage.height/2)
end

return Controls