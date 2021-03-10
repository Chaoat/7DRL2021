local Game = {}

GlobalTurnTime = 0.2
GlobalTileDims = {16, 16}

function Game.new()
	local mapRadius = 7
	local segmentSize = 6
	local game = {world = World.new(mapRadius, segmentSize), turnSystem = TurnCalculation.newSystem(GlobalTurnTime), mainCamera = Camera.new(800, 450, GlobalTileDims[1], GlobalTileDims[2])}
	game.player = Player.new((mapRadius + 0.5)*segmentSize - 1, 0, game.world)
	game.mainCamera.followingBody = game.player.character.body
	return game
end

function Game.update(game, dt)
	TurnCalculation.updateTurn(game, dt)
	Camera.update(game.mainCamera, dt)
end

function Game.draw(game)
	--print("newDrawStep")
	Camera.reset(game.mainCamera)
	
	World.draw(game.world, not game.turnSystem.turnRunning, game.mainCamera)
	Player.drawTargettingHighlight(game.player, game.mainCamera)
	
	Camera.draw(0, 0, game.mainCamera)
	
	Interface.drawPlayerWeapons(0, 450, game.player)
end

function Game.handleKeyboardInput(game, key)
	--if Controls.checkControl(key, "turnEnd") then
	--	TurnCalculation.runTurn(game.turnSystem, game.world)
	--elseif Controls.checkControl(key, "topLeft") then
	--	local character = game.world.characters[1]
	--	Character.moveCharacter(character, -1, -1)
	--	TurnCalculation.runTurn(game.turnSystem, game.world)
	--end
	
	Player.keyInput(game.turnSystem, game.player, key)
end

return Game