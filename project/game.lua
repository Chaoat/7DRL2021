local Game = {}

GlobalTurnTime = 0.2
GlobalTileDims = {16, 16}

local currentLevel = 1
local levelStartTexts = {}
do --initTexts
	levelStartTexts[1] = {"I", "placeholder"}
	levelStartTexts[2] = {"II", "placeholder"}
	levelStartTexts[3] = {"III", "placeholder"}
end

function Game.new()
	local mapRadius = 7
	local segmentSize = 6
	local game = {world = World.new(mapRadius, segmentSize), turnSystem = TurnCalculation.newSystem(GlobalTurnTime), mainCamera = Camera.new(800, 450, GlobalTileDims[1], GlobalTileDims[2]), examining = false, transition = {over = true}}
	
	Game.spawnPlayer(game)
	
	InfoScreen.displayInfoScreen(levelStartTexts[currentLevel][1], levelStartTexts[currentLevel][2])
	
	return game
end

local playerAngles = {0, math.pi/2, math.pi, -math.pi/2}
local startingKits = {}
startingKits[1] = {{"Bolt Caster", 30}, {"Force Wave", 6}}
startingKits[2] = {{"Bolt Caster", 30}, {"Force Wave", 18}, {"Hydrocarbon Explosive", 6}}
startingKits[3] = {{"Bolt Caster", 30}, {"Force Wave", 18}, {"Hydrocarbon Explosive", 6}}
function Game.spawnPlayer(game)
	local side = math.floor(Random.randomBetweenPoints(0, 4))
	local angle, angleI = Random.randomFromList(playerAngles)
	table.remove(playerAngles, angleI)
	
	local spawnX = Misc.round(44*math.cos(angle))
	local spawnY = Misc.round(44*math.sin(angle))
	
	game.player = Player.new(spawnX, spawnY, game.world, startingKits[currentLevel])
	game.mainCamera.followingBody = game.player.character.body
	Camera.update(game.mainCamera, game.examining, 0)
end

function Game.update(game, dt)
	TurnCalculation.updateTurn(game, dt)
	if not InfoScreen.getDisplaying() then
		Camera.update(game.mainCamera, game.examining, dt)
	end
	
	if game.player.dead then
		TurnCalculation.runTurn(game.turnSystem, game.world)
	end
	
	if not game.transition.over then
		game.transition.updateFunc(dt)
	end
end

function Game.nextLevel(game)
	if currentLevel == 3 then
		game.transition = ScreenTransitions.win()
	else
		game.transition = ScreenTransitions.fadeToBlack(0, 1, 1)
		game.world.itemLevel = game.world.itemLevel + 1
		
		Character.clearCharacters(game.world.characters, game.world.enemies)
		Character.clearCharacters(game.world.characters, {game.player})
		
		game.world.enemies = {}
		MapGeneration.multiplyThreat(game.world.map.structure, 2)
		MapGeneration.populateEnemies(game.world.map.structure, game.world)
		
		Vision.fullResetVision(game.world.map)
		currentLevel = currentLevel + 1
		Game.spawnPlayer(game)
		InfoScreen.displayInfoScreen(levelStartTexts[currentLevel][1], levelStartTexts[currentLevel][2])
	end
end

local function startExamining(game)
	game.examining = {game.player.character.body.tile.x, game.player.character.body.tile.y}
end

local function stopExamining(game)
	local examiningTile = Map.getTile(game.world.map, game.examining[1], game.examining[2])
	if examiningTile.visible and #examiningTile.bodies["character"] > 0 then
		local character = examiningTile.bodies["character"][1].parent
		InfoScreen.displayInfoScreen(character.name, character.text)
	end
	
	game.examining = false
end

function Game.examineWeapon(game, weaponName, weaponText)
	InfoScreen.displayInfoScreen(weaponName, weaponText)
	game.examining = false
end

function Game.resize(game, width, height)
	width = math.min(width, 1000)
	height = math.min(height, 1000)
	game.mainCamera = Camera.new(width, height - 150, GlobalTileDims[1], GlobalTileDims[2])
	game.mainCamera.followingBody = game.player.character.body
end

local function examiningMoveInput(game, key)
	local moveX = 0
	local moveY = 0
	if Controls.checkControl(key, "topLeft") then
		moveX = -1
		moveY = -1
	elseif Controls.checkControl(key, "top") then
		moveX = 0
		moveY = -1
	elseif Controls.checkControl(key, "topRight") then
		moveX = 1
		moveY = -1
	elseif Controls.checkControl(key, "left") then
		moveX = -1
		moveY = 0
	elseif Controls.checkControl(key, "center") then
		moveX = 0
		moveY = 0
	elseif Controls.checkControl(key, "right") then
		moveX = 1
		moveY = 0
	elseif Controls.checkControl(key, "botLeft") then
		moveX = -1
		moveY = 1
	elseif Controls.checkControl(key, "bot") then
		moveX = 0
		moveY = 1
	elseif Controls.checkControl(key, "botRight") then
		moveX = 1
		moveY = 1
	else
		for i = 1, #game.player.weapons do
			if Controls.checkControl(key, "weapon" .. i) then
				local weapon = game.player.weapons[i]
				Game.examineWeapon(game, weapon.name, Weapon.getWeaponDescription(weapon.name))
				return
			end
		end
	end
	
	game.examining[1] = game.examining[1] + moveX
	game.examining[2] = game.examining[2] + moveY
end

function Game.handleKeyboardInput(game, key)
	--if Controls.checkControl(key, "turnEnd") then
	--	TurnCalculation.runTurn(game.turnSystem, game.world)
	--elseif Controls.checkControl(key, "topLeft") then
	--	local character = game.world.characters[1]
	--	Character.moveCharacter(character, -1, -1)
	--	TurnCalculation.runTurn(game.turnSystem, game.world)
	--end
	
	if game.transition.over then
		if not InfoScreen.getDisplaying() then
			if Controls.checkControl(key, "examine") then
				if game.examining then
					stopExamining(game)
				else
					startExamining(game)
				end
			elseif game.examining then
				examiningMoveInput(game, key)
			else
				Player.keyInput(game.turnSystem, game.player, key)
			end
		else
			if Controls.checkControl(key, "return") then
				InfoScreen.closeInfoScreen()
			end
		end
	end
end

function Game.draw(game)
	local ScreenWidth = math.min(love.graphics.getWidth(), 1000)
	local xOff = math.ceil((love.graphics.getWidth() - ScreenWidth)/2)
	local ScreenHeight = math.min(love.graphics.getHeight(), 1000)
	local yOff = math.floor((love.graphics.getHeight() - ScreenHeight)/2)
	
	--print("newDrawStep")
	Camera.reset(game.mainCamera)
	
	Stars.draw(xOff, yOff, game.mainCamera.starSystem, game.mainCamera)
	World.draw(game.world, not game.turnSystem.turnRunning, game.mainCamera)
	Player.drawTargettingHighlight(game.player, game.mainCamera)
	
	--Pathfinding.visualizeMap(game.world.pathfindingMap, game.player.character.body, game.mainCamera)
	InfoScreen.drawExamineCursor(game, game.mainCamera)
	Camera.draw(xOff, yOff, game.mainCamera)
	
	Interface.drawPlayerInterface(xOff, yOff + ScreenHeight - 150, ScreenWidth, 150, game.player)
	InfoScreen.drawInfoScreen(xOff + 20, yOff + 20, ScreenWidth - 40, ScreenHeight - 250)
	
	--local lX, lY = Camera.screenToLogicCoords(love.mouse.getX(), love.mouse.getY(), {0, 0}, game.mainCamera)
	--Vision.debugDrawRoute(Misc.round(lX - game.mainCamera.x), Misc.round(lY - game.mainCamera.y), game.player.character.body.tile.x, game.player.character.body.tile.y, game.mainCamera)
	
	if not game.transition.over then
		game.transition.drawFunc()
	end
end

return Game