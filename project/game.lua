local Game = {}

local currentLevel = 1
local levelStartTexts = {}
do --initTexts
	levelStartTexts[1] = {"I", "The Devourer came over a Millenium ago, laying his yoke on all within your system and forcing all into servitude. After a century long war, your ancestors defeated him, breaking free of their chains and tasting freedom for the first time in generations. The Devourer was not destroyed however, too great was his power, but a Labyrinth orbiting the star of your system was constructed to house his sleeping spirit. Those bound within time however can not permanently chain the timeless, and your ancestors knew that shackles forged by mortal hands would need mortal upkeep. They foresaw that their chains would last 1000 years, after which three mortals would be required to venture into the Labyrinth and renew them over the course of a century.\n\nIt is 1000 years later, and The Devourer has been dreaming. The need for renewal is becoming apparent, as The Devourer's slumber wanes, evil forces have been growing in strength throughout the system. You have been selected to take part in the first stage of the renewal, and the future of your people goes with you."}
	levelStartTexts[2] = {"II", "It has been 33 years, and the time approaches for the second stage of the renewal. The first Runner never returned, their lifeless body found within the Labyrinth by the techs sent to replace the old arnaments in the Cargo Pods. Despite this, it is clear that they succeeded, as the evil forces within the system have diminished somewhat, and the Labyrinth once again slumbered. Now it is awake once again, and it is your turn to venture within."}
	levelStartTexts[3] = {"III", "The last stage awaits, deep within The Labyrinth the last Shackle frays. You were chosen from birth for this mission, child of the first Runner, brought up on tales of their bravery. The Devourer knows too that this is his final chance, his dreams have grown in strength, and the allies that stand beside him are truly terrifying. Raids on the inner worlds by terrible demons are now a common occurrence, providing but a taste of the horror that awaits if you fail in your mission."}
end

local shipAmbience = Sound.newSound("shipAmbience.ogg", 0.4)
shipAmbience:setLooping(true)

local playerAngles
function Game.new()
	playerAngles = {0, math.pi/2, math.pi, -math.pi/2}
	currentLevel = 1
	
	local mapRadius = 9
	local segmentSize = 6
	local game = {world = World.new(mapRadius, segmentSize), turnSystem = TurnCalculation.newSystem(GlobalTurnTime), mainCamera = Camera.new(800, 450, GlobalTileDims[1], GlobalTileDims[2]), examining = false, transition = {over = true}}
	
	Game.spawnPlayer(game)
	
	Game.resize(game, love.graphics.getWidth(), love.graphics.getHeight())
	
	InfoScreen.displayInfoScreen(levelStartTexts[currentLevel][1], levelStartTexts[currentLevel][2])
	
	shipAmbience:seek(0)
	shipAmbience:play()
	
	Tile.updateCanvas(game.world.map, game.mainCamera)
	
	return game
end


local startingKits = {}
startingKits[1] = {{"Bolt Caster", 45}, {"Force Wave", 6}}
startingKits[2] = {{"Bolt Caster", 45}, {"Force Wave", 18}, {"Emergency Thruster", 4}}
startingKits[3] = {{"Bolt Caster", 45}, {"Force Wave", 18}, {"Emergency Thruster", 4}, {"Entropy Orb", 10}, {"Sanctuary Sphere", 3}}
function Game.spawnPlayer(game)
	local side = math.floor(Random.randomBetweenPoints(0, 4))
	local angle, angleI = Random.randomFromList(playerAngles)
	table.remove(playerAngles, angleI)
	
	local spawnX = Misc.round(54*math.cos(angle))
	local spawnY = Misc.round(54*math.sin(angle))
	
	--game.mainCamera.x = spawnX
	--game.mainCamera.y = spawnY
	--Camera.update(game.mainCamera, false, game.world, 0)
	
	game.player = Player.new(spawnX, spawnY, game.world, startingKits[currentLevel], game)
	game.mainCamera.followingBody = game.player.character.body
end

function Game.update(game, dt)
	TurnCalculation.updateTurn(game, dt)
	if not InfoScreen.getDisplaying() then
		Camera.update(game.mainCamera, game.examining, game.world, dt)
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
		Weapon.clearDeadly(game.world.bullets, game.world.map)
		Weapon.clearDeadly(game.world.explosions, game.world.map)
		
		game.world.enemies = {}
		if currentLevel == 1 then
			MapGeneration.multiplyThreat(game.world.map.structure, 2)
		else
			MapGeneration.multiplyThreat(game.world.map.structure, 1.5)
		end
		
		MapGeneration.populateEnemies(game.world.map.structure, game.world)
		
		Vision.fullResetVision(game.world.map)
		currentLevel = currentLevel + 1
		Game.spawnPlayer(game)
		InfoScreen.displayInfoScreen(levelStartTexts[currentLevel][1], levelStartTexts[currentLevel][2])
		
		Tile.updateCanvas(game.world.map, game.mainCamera)
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
	
	Camera.moveCamera(game.mainCamera, game.world, game.player.character.body.x, game.player.character.body.y)
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
	
	if game.player.dead then
		if Controls.checkControl(key, "restart") then
			globalGame = Game.new()
		end
	else
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