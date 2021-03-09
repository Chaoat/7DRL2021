local Interface = {}

function Interface.drawPlayerWeapons(x, y, player)
	Font.setFont("437", 14)
	Shader.pixelateTextShader:send("threshold", 0.5)
	love.graphics.setShader(Shader.pixelateTextShader)
	
	for i = 1, #player.weapons do
		local weapon = player.weapons[i]
		local columns, colour = Weapon.getPrintInfo(weapon.name)
		
		local topX = x + i*30
		local topY = y + 5
		
		love.graphics.setColor(colour)
		for j = 1, #columns do
			love.graphics.printf(columns[j], topX + (j - 1)*10, topY + 30 + 10*(j - 1), 10, "left")
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
		love.graphics.printf(boxText ..weapon.ammo, topX, topY, 30, "left")
	end
	
	love.graphics.setShader()
end

return Interface