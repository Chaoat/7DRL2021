Body = require("body")
PhysicsSystem = require("physicsSystem")
World = require("world")
Game = require("game")
Camera = require("camera")
CanvasCache = require("canvasCache")
Map = require("map")
Tile = require("tile")
Image = require("image")
Misc = require("misc")
Controls = require("controls")
TurnCalculation = require("turnCalculation")
Layers = require("layers")
Character = require("character")
Vector = require("vector")
Player = require("player")
Vision = require("vision")
MapGeneration = require("mapGeneration")
Random = require("randomFunctions")
Weapon = require("weapon")
Explosion = require("explosion")
Font = require("font")
Letter = require("letter")
Shader = require("shader")
TileColour = require("tileColour")
Interface = require("interface")
TrackingLines = require("trackingLines")
Pathfinding = require("pathfinding")
Chest = require("chest")
InfoScreen = require("infoScreen")
ScreenTransitions = require("screenTransitions")
Stars = require("stars")

Shield = require("shield")
EndOrb = require("endOrb")
Wall = require("wall")
Enemy = require("enemy")

local profile = require("profile")

GlobalClock = 0

globalGame = nil
local testStructure
function love.load()
	math.randomseed(os.clock())
	love.keyboard.setKeyRepeat(true)
	
	globalGame = Game.new()
end

function love.update(dt)
	GlobalClock = GlobalClock + dt
	
	Game.update(globalGame, dt)
	
	profile.update(dt)
end

function love.resize(w, h)
	Game.resize(globalGame, w, h)
end

function love.keypressed(key, scancode, isrepeat)
	Game.handleKeyboardInput(globalGame, key)
	
	if key == "f5" then
		profile.start(5)
	end
end

function love.draw()
	Game.draw(globalGame)
end