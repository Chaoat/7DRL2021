local Interface = {}

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
		for j = 1, #columns do
			love.graphics.printf(columns[j], topX + (j - 1)*10 + 28, topY + 2 + 12*(j - 1), 200, "left")
		end
		
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

return Interface