local Player = {}

local function updatePlayerTargettingLine(player)
	if player.targettingLine then
		local playerTile = player.character.body.tile
		local newAngle = math.atan2(player.targettingCoords[2] - player.character.body.y, player.targettingCoords[1] - player.character.body.x)
		TrackingLines.updatePoints(player.targettingLine, playerTile.x, playerTile.y, player.targettingCoords[1], player.targettingCoords[2])
	end
end

function Player.new(x, y, world)
	local character = Character.new(Body.new(x, y, world, 100, 1, 0, "character"), 200, Image.letterToImage("@", {1, 1, 1, 1}))
	local player = {character = character, viewRange = 15, weapons = {}, firingWeapon = false, chainFiring = false, targettingCoords = {0, 0}, targettingLine = false, selectingTarget = false, targettingCharacter = false}
	
	local function onMove(oldTile)
		if oldTile then
			Map.iterateOverTileRange(world.map, {oldTile.x - player.viewRange, oldTile.x + player.viewRange}, {oldTile.y - player.viewRange, oldTile.y + player.viewRange}, 
			function(tile)
				tile.visible = false
			end)
		end
		local playerTile = player.character.body.tile
		Vision.checkVisible(world, playerTile.x, playerTile.y, player.viewRange)
		
		updatePlayerTargettingLine(player)
		Chest.getItemsOnTile(playerTile, player)
		
		--print(player.character.body.tile.x .. "--" .. player.character.body.tile.y)
	end
	
	onMove()
	Body.addMoveCallback(character.body, onMove)
	
	Player.getWeapon(player, "Bolt Caster", 30)
	--Player.getWeapon(player, "Hydrocarbon Explosive", 10)
	--Player.getWeapon(player, "Force Wave", 10)
	--Player.getWeapon(player, "Matter Compressor", 30)
	
	return player
end

function Player.getWeapon(player, weaponName, ammo)
	local weapon = false
	for i = 1, #player.weapons do
		if player.weapons[i].name == weaponName then
			weapon = player.weapons[i]
			break
		end
	end
	
	if not weapon then
		weapon = {name = weaponName, ammo = 0}
		
		table.insert(player.weapons, weapon)
	end
	
	weapon.ammo = weapon.ammo + ammo
end

local function playerMove(player, turnSystem, xDir, yDir)
	if player.selectingTarget then
		player.targettingCoords = {player.targettingCoords[1] + xDir, player.targettingCoords[2] + yDir}
		updatePlayerTargettingLine(player)
	else
		Character.moveCharacter(player.character, xDir, yDir)
		
		if player.firingWeapon then
			local weapon = player.weapons[player.firingWeapon]
			TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire(weapon.name, player.character.body.x, player.character.body.y, player.targettingCoords[1], player.targettingCoords[2], player.character.body, player.character.body.world), player.character.body, 0, turnSystem)
			weapon.ammo = weapon.ammo - 1
			Enemy.shout(player.character.body, player.viewRange, 10)
			
			if not player.chainFiring or weapon.ammo <= 0 then
				player.firingWeapon = false
				if player.targettingLine then
					player.targettingLine.destroy = true
				end
				player.targettingLine = false
			end
		end
		
		TurnCalculation.runTurn(turnSystem, player.character.world)
	end
end

local function playerTrackCharacter(player)
	if player.targettingCharacter and player.firingWeapon then
		local weaponBullet = Weapon.getSimulationTemplate(player.weapons[player.firingWeapon].name)
		if weaponBullet then
			player.targettingCoords = TrackingLines.findIntercept(player.character.body.x, player.character.body.y, weaponBullet.speed, player.targettingCharacter)
			updatePlayerTargettingLine(player)
		end
	end
end

local function startTargetSelection(player)
	if not player.firingWeapon and not player.selectingTarget then
		local body = player.character.body
		local closestEnemy = Vision.findClosestEnemy(body.world, body.x, body.y, player.viewRange)
		if closestEnemy then
			player.targettingCoords = {closestEnemy.x, closestEnemy.y}
		else
			player.targettingCoords = {body.x, body.y}
		end
	end
	player.selectingTarget = true
	player.targettingCharacter = false
end

local function stopTargetSelection(player)
	player.selectingTarget = false
	local tile = Map.getTile(player.character.body.map, player.targettingCoords[1], player.targettingCoords[2])
	if #tile.bodies["character"] > 0 then
		player.targettingCharacter = tile.bodies["character"][1].parent
		playerTrackCharacter(player)
	end
end

local function toggleSelectingTarget(player)
	if not player.selectingTarget then
		startTargetSelection(player)
	else
		stopTargetSelection(player)
	end
end

local function playerSelectWeapon(player, index)
	if player.firingWeapon == index then
		--if Controls.checkControlHeld("chainFire") ~= player.chainFiring then
		--	player.chainFiring = Controls.checkControlHeld("chainFire")
		--else
		if player.selectingTarget then
			stopTargetSelection(player)
		else
			player.firingWeapon = false
			if player.targettingLine then
				player.targettingLine.destroy = true
			end
			player.targettingLine = false
		end
		--end
	elseif player.weapons[index].ammo > 0 then
		startTargetSelection(player)
		if player.targettingLine then
			player.targettingLine.destroy = true
		end
		
		local body = player.character.body
		player.targettingLine = Weapon.simulateFire(player.weapons[index].name, body.x, body.y, player.targettingCoords[1], player.targettingCoords[2], body.world)
		player.firingWeapon = index
		player.chainFiring = Controls.checkControlHeld("chainFire")
		
		playerTrackCharacter(player)
	end
end

function Player.endTurnUpdate(player)
	playerTrackCharacter(player)
end

function Player.keyInput(turnSystem, player, key)
	if Controls.checkControl(key, "topLeft") then
		playerMove(player, turnSystem, -1, -1)
	elseif Controls.checkControl(key, "top") then
		playerMove(player, turnSystem, 0, -1)
	elseif Controls.checkControl(key, "topRight") then
		playerMove(player, turnSystem, 1, -1)
	elseif Controls.checkControl(key, "left") then
		playerMove(player, turnSystem, -1, 0)
	elseif Controls.checkControl(key, "center") then
		playerMove(player, turnSystem, 0, 0)
	elseif Controls.checkControl(key, "right") then
		playerMove(player, turnSystem, 1, 0)
	elseif Controls.checkControl(key, "botLeft") then
		playerMove(player, turnSystem, -1, 1)
	elseif Controls.checkControl(key, "bot") then
		playerMove(player, turnSystem, 0, 1)
	elseif Controls.checkControl(key, "botRight") then
		playerMove(player, turnSystem, 1, 1)
	--elseif Controls.checkControl(key, "selectTarget") then
	--	toggleSelectingTarget(player)
	else
		for i = 1, #player.weapons do
			if Controls.checkControl(key, "weapon" .. i) then
				playerSelectWeapon(player, i)
			end
		end
	end
end

function Player.drawTargettingHighlight(player, camera)
	if player.selectingTarget then
		local tile = Map.getTile(player.character.body.map, player.targettingCoords[1], player.targettingCoords[2])
		
		Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.setLineStyle("rough")
			love.graphics.setLineWidth(2)
			love.graphics.rectangle("line", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
		end)
	end
end

return Player