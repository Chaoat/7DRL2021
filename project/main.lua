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

local globalGame
function love.load()
	globalGame = Game.new()
end

function love.update(dt)
	Game.update(globalGame, dt)
end

function love.keypressed(key, scancode, isrepeat)
	Game.handleKeyboardInput(globalGame, key)
end

function love.draw()
	Game.draw(globalGame)
end