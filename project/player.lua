local Player = {}

function Player.new(x, y, world)
	local character = Character.new(Body.new(x, y, world, 100, 1, 0, "character"), 200)
	local player = {character = character, viewRange = 20}
	
	local function updateVision(oldTile)
		Map.iterateOverTileRange(world.map, {oldTile.x - player.viewRange, oldTile.x + player.viewRange}, {oldTile.y - player.viewRange, oldTile.y + player.viewRange}, 
		function(tile)
			tile.visible = false
		end)
		local playerTile = player.character.body.tile
		Vision.checkVisible(world, playerTile.x, playerTile.y, player.viewRange)
	end
	
	Body.addMoveCallback(character.body, updateVision)
	
	return player
end

local function playerMove(player, turnSystem, xDir, yDir)
	Character.moveCharacter(player.character, xDir, yDir)
	
	TurnCalculation.addWeaponDischarge(function()
		return Weapon.boltCaster(player.character.body.x, player.character.body.y, 0, 0, player.character.body.world)
	end, 0, turnSystem)
	
	TurnCalculation.runTurn(turnSystem, player.character.world)
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
	end
end

return Player