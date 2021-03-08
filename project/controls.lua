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

addControls("turnEnd", {"space"})

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