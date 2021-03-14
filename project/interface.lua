local Interface = {}

function Interface.drawPlayerInterface(x, y, width, height, player)
	Interface.drawPlayerWeapons(x, y, player)
	Interface.drawPlayerControls(x + width - 380, y, 250)
	Interface.drawPlayerHealth(x + width - 75, y + height - 75, 50, player)
end

function Interface.drawPlayerWeapons(x, y, player)
	Font.setFont("437", 16)
	Shader.pixelateTextShader:send("threshold", 0.5)
	love.graphics.setShader(Shader.pixelateTextShader)
	
	for i = 1, #player.weapons do
		local weapon = player.weapons[i]
		local columns, colour = Weapon.getPrintInfo(weapon.name)
		
		local xShift = 150*math.floor((i - 1)/4)
		local yShift = 30*((i - 1)%4)
		
		local topX = x + 10 + xShift
		local topY = y + 5 + yShift
		
		love.graphics.setColor(colour)
		if player.firingWeapon and player.weapons[player.firingWeapon].name == weapon.name then
			local flash = Misc.oscillateBetween(0, 1, 0.2)
			love.graphics.setColor(colour[1] + flash, colour[2] + flash, colour[3] + flash, 1)
		end
		for j = 1, #columns do
			love.graphics.printf(columns[j], topX + (j - 1)*10 + 28, topY + 2 + 12*(j - 1), 200, "left")
		end
		
		love.graphics.setColor(colour)
		local boxText = "[" .. i .. "] "
		if weapon.ammo == 0 then
			boxText = "[N] "
		elseif player.firingWeapon == i then
			if player.chainFiring then
				boxText = "[*] "
			else
				boxText = "[x] "
			end
		end
		
		if globalGame.examining then
			local flash = math.max(2*((GlobalClock%1) - 0.5), 0)
			love.graphics.setColor(colour[1] + flash, colour[2] + flash, colour[3] + flash, 1)
		end
		love.graphics.printf(boxText, topX, topY, 30, "left")
		love.graphics.setColor(colour)
		love.graphics.printf(weapon.ammo, topX + 4, topY + 14, 30, "right")
	end
	
	love.graphics.setShader()
end

function Interface.drawPlayerHealth(centerX, centerY, radius, player)
	love.graphics.setColor(1, 0, 0, 1)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(10)
	love.graphics.circle("line", centerX, centerY, radius)
	
	local body = player.character.body
	
	love.graphics.setColor(0, 1, 0, 1)
	love.graphics.arc("line", "open", centerX, centerY, radius, -math.pi/2, -math.pi/2 - (body.health/body.maxHealth)*(2*math.pi), 100)
	
	love.graphics.setColor(1, 1, 1, 1)
	Font.setFont("437", 20)
	love.graphics.printf(math.ceil(body.health), centerX - 30, centerY - 10, 60, "center")
end

function Interface.drawPlayerControls(x, y, width)
	local controlText = ""
	controlText = controlText .. "keypad/qwe-asd-z c : move" .. "\n"
	controlText = controlText .. "kp5/space : wait" .. "\n"
	controlText = controlText .. "    1-0 : prepare weapon" .. "\n"
	controlText = controlText .. "        i : examine" .. "\n"
	controlText = controlText .. "lshift + 1-0 : chain fire" .. "\n"
	controlText = controlText .. "    tab/t : cycle targets" .. "\n"
	
	love.graphics.setColor(1, 1, 1, 1)
	Font.setFont("437", 16)
	love.graphics.printf(controlText, x, y + 20, width, "left")
end

return Interface