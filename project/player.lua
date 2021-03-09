local Player = {}

function Player.new(x, y, world)
	local character = Character.new(Body.new(x, y, world, 100, 1, 0, "character"), 200, Image.letterToImage("@", {1, 1, 1, 1}, 20, 20))
	local player = {character = character, viewRange = 20, weapons = {}, firingWeapon = false, chainFiring = false, targettingCoords = {0, 0}, targettingLine = false}
	
	local function onMove(oldTile)
		if oldTile then
			Map.iterateOverTileRange(world.map, {oldTile.x - player.viewRange, oldTile.x + player.viewRange}, {oldTile.y - player.viewRange, oldTile.y + player.viewRange}, 
			function(tile)
				tile.visible = false
			end)
		end
		local playerTile = player.character.body.tile
		Vision.checkVisible(world, playerTile.x, playerTile.y, player.viewRange)
		
		if player.targettingLine then
			local newAngle = math.atan2(player.targettingCoords[2] - player.character.body.y, player.targettingCoords[1] - player.character.body.x)
			TrackingLines.updatePoints(player.targettingLine, playerTile.x, playerTile.y, newAngle)
		end
	end
	
	onMove()
	Body.addMoveCallback(character.body, onMove)
	
	Player.getWeapon(player, "Bolt Caster", 10)
	
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
	Character.moveCharacter(player.character, xDir, yDir)
	
	--TurnCalculation.addWeaponDischarge(function()
	--	return Weapon.boltCaster(player.character.body.x, player.character.body.y, 0, 0, player.character.body.world)
	--end, 0, turnSystem)
	
	if player.firingWeapon then
		local weapon = player.weapons[player.firingWeapon]
		TurnCalculation.addWeaponDischarge(Weapon.prepareWeaponFire(weapon.name, player.character.body.x, player.character.body.y, player.targettingCoords[1], player.targettingCoords[2], player.character.body.world), 0, turnSystem)
		weapon.ammo = weapon.ammo - 1
		
		if not player.chainFiring or weapon.ammo <= 0 then
			player.firingWeapon = false
			player.targettingLine.destroy = true
			player.targettingLine = false
		end
	end
	
	TurnCalculation.runTurn(turnSystem, player.character.world)
end

local function playerSelectWeapon(player, index)
	if player.firingWeapon == index then
		if Controls.checkControlHeld("chainFire") ~= player.chainFiring then
			player.chainFiring = Controls.checkControlHeld("chainFire")
		else
			player.firingWeapon = false
			player.targettingLine.destroy = true
			player.targettingLine = false
		end
	elseif player.weapons[index].ammo > 0 then
		local body = player.character.body
		player.targettingLine = Weapon.simulateFire(player.weapons[index].name, body.x, body.y, player.targettingCoords[1], player.targettingCoords[2], body.world)
		player.firingWeapon = index
		player.chainFiring = Controls.checkControlHeld("chainFire")
	end
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
	else
		for i = 1, #player.weapons do
			if Controls.checkControl(key, "weapon" .. i) then
				playerSelectWeapon(player, i)
			end
		end
	end
end

return Player