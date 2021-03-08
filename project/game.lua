local Game = {}

function Game.new()
	local game = {world = World.new(), turnSystem = TurnCalculation.newSystem(0.2), mainCamera = Camera.new(800, 600, 20, 20)}
	game.player = Player.new(0, 0, game.world)
	return game
end

function Game.update(game, dt)
	TurnCalculation.updateTurn(game, dt)
end

function Game.draw(game)
	--print("newDrawStep")
	Camera.reset(game.mainCamera)
	
	World.draw(game.world, game.mainCamera)
	Body.debugDrawBodies(game.world.physicsSystem.bodies, game.mainCamera)
	
	Camera.draw(0, 0, game.mainCamera)
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