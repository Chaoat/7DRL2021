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
MapGeneration = require("MapGeneration")
Random = require("randomFunctions")
Weapon = require("weapon")
Explosion = require("explosion")
Font = require("font")
Letter = require("letter")
Shader = require("shader")
TileColour = require("tileColour")
Interface = require("interface")
TrackingLines = require("trackingLines")

Wall = require("wall")
Enemy = require("enemy")

local profile = require("profile")

GlobalClock = 0

local globalGame
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

function love.keypressed(key, scancode, isrepeat)
	Game.handleKeyboardInput(globalGame, key)
	
	if key == "f5" then
		profile.start(5)
	end
end

function love.draw()
	Game.draw(globalGame)
end