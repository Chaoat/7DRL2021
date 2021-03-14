local Player = {}

local function updatePlayerTargettingLine(player)
	if player.targettingLine and player.targettingCoords then
		local playerTile = player.character.body.tile
		local newAngle = math.atan2(player.targettingCoords[2] - player.character.body.y, player.targettingCoords[1] - player.character.body.x)
		TrackingLines.updatePoints(player.targettingLine, playerTile.x, playerTile.y, player.targettingCoords[1], player.targettingCoords[2])
	end
end

function Player.new(x, y, world, startingKit, game)
	local character = Character.new(Body.new(x, y, world, 200, 1, 0, "character"), 200, Image.letterToImage("@", {1, 1, 1, 1}), "The Runner", "Selected through a year long competition between all the people of your generation, the champion chosen not just by their skill in bolt and wave, but by their quick wit and determined attitude. Many of your peers shared a mastery of all these skills, however you alone had the dedication and courage necessary to guard yourself from the psychic emanations of The Devourer. The final test awaits.")
	local player = {character = character, viewRange = 15, enemyTargets = {}, enemyTargetI = 0, weapons = {}, firingWeapon = false, chainFiring = false, targettingCoords = {0, 0}, targettingLine = false, selectingTarget = false, targettingCharacter = false}
	
	character.body.bloody = true
	
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
		
		Tile.updateCanvas(world.map, game.mainCamera)
		
		--print(player.character.body.tile.x .. "--" .. player.character.body.tile.y)
	end
	
	onMove()
	Body.addMoveCallback(character.body, onMove)
	
	for i = 1, #startingKit do
		Player.getWeapon(player, startingKit[i][1], startingKit[i][2])
	end
	
	--Player.getWeapon(player, "Bolt Caster", 30)
	--Player.getWeapon(player, "Hydrocarbon Explosive", 10)
	--Player.getWeapon(player, "Force Wave", 10)
	--Player.getWeapon(player, "Matter Compressor", 30)
	--Player.getWeapon(player, "Emergency Thruster", 30)
	--Player.getWeapon(player, "Entropy Orb", 30)
	--Player.getWeapon(player, "Sanctuary Sphere", 30)
	--Player.getWeapon(player, "Annihilator Cannon", 30)
	
	--Enemy.spawnEnemy("Golem", x - 2, y, world)
	
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
		if globalGame then
			Game.examineWeapon(globalGame, weapon.name, Weapon.getWeaponDescription(weapon.name))
		end
	end
	
	weapon.ammo = weapon.ammo + ammo
end

local function playerMove(player, turnSystem, xDir, yDir)
	if player.selectingTarget then
		player.targettingCoords = {player.targettingCoords[1] + xDir, player.targettingCoords[2] + yDir}
		if not player.examining then
			updatePlayerTargettingLine(player)
		end
	else
		Character.moveCharacter(player.character, xDir, yDir)
		
		if player.firingWeapon then
			local weapon = player.weapons[player.firingWeapon]
			TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire(weapon.name, player.targettingCoords[1], player.targettingCoords[2], player.character.body, player.character.body.world), player.character.body, 0, turnSystem)
			weapon.ammo = weapon.ammo - 1
			Enemy.shout(player.character.body, player.viewRange, 10)
			
			if not player.chainFiring or weapon.ammo <= 0 then
				player.firingWeapon = false
				if player.targettingLine then
					player.targettingLine.destroy = true
				end
				player.targettingLine = false
				player.targettingCharacter = false
			end
		end
		
		TurnCalculation.runTurn(turnSystem, player.character.world)
	end
end

local function cycleTargets(player)
	if #player.enemyTargets > 0 then
		player.enemyTargetI = 1 + (player.enemyTargetI%#player.enemyTargets)
		
		local target = player.enemyTargets[player.enemyTargetI]
		player.targettingCoords = {target.x, target.y}
		updatePlayerTargettingLine(player)
	end
end

local function playerTrackCharacter(player)
	if player.targettingCharacter and player.firingWeapon then
		if player.targettingCharacter.body.destroy then
			player.targettingCharacter = false
		else
			local weaponBullet = Weapon.getSimulationTemplate(player.weapons[player.firingWeapon].name)
			if weaponBullet then
				player.targettingCoords = {player.targettingCharacter.body.tile.x, player.targettingCharacter.body.tile.y}--TrackingLines.findIntercept(player.character.body.x, player.character.body.y, weaponBullet.speed, player.targettingCharacter)
				updatePlayerTargettingLine(player)
			end
		end
	end
end

local function startTargetSelection(player)
	if not player.firingWeapon and not player.selectingTarget then
		local body = player.character.body
		player.enemyTargets = Vision.findVisibleEnemies(body.world, body.x, body.y, player.viewRange)
		player.enemyTargetI = 0
		if #player.enemyTargets > 0 then
			cycleTargets(player)
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

local areaWeapons = {}
areaWeapons["Force Wave"] = true

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
			player.targettingCharacter = false
		end
		--end
	elseif player.weapons[index].ammo > 0 then
		if not areaWeapons[player.weapons[index].name] then
			startTargetSelection(player)
		end
		
		if player.targettingLine then
			player.targettingLine.destroy = true
		end
		
		local body = player.character.body
		if player.weapons[index].name == "Sanctuary Sphere" then
			player.targettingCoords = {body.x, body.y}
		end
		
		if player.targettingCoords then
			player.targettingLine = Weapon.simulateFire(player.weapons[index].name, body.x, body.y, player.targettingCoords[1], player.targettingCoords[2], body.world)
		end
		if player.targettingLine and player.targettingLine.colour then
			player.targettingLine.colour = {0, 1, 0, 0.4}
		end
		player.firingWeapon = index
		player.chainFiring = Controls.checkControlHeld("chainFire")
		
		playerTrackCharacter(player)
	end
end

function Player.endTurnUpdate(player)
	local distFromCenter = math.sqrt(player.character.body.x^2 + player.character.body.y^2)
	if (player.character.body.destroy or distFromCenter >= 75) and not player.dead and globalGame.transition.over then
		if distFromCenter >= 75 then
			player.spaced = true
		end
		player.dead = true
		globalGame.transition = ScreenTransitions.die()
	end
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
	elseif Controls.checkControl(key, "cycleTargets") then
		cycleTargets(player)
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
		
		love.graphics.setColor(1, 1, 1, 1)
		Image.drawImage(Image.getImage("targetCursor"), camera, tile.x, tile.y, GlobalClock)
	elseif player.targettingCoords and player.firingWeapon then
		love.graphics.setColor(1, 1, 1, 1)
		Image.drawImage(Image.getImage("targettingReticle"), camera, player.targettingCoords[1], player.targettingCoords[2], GlobalClock)
	end
end

return Player