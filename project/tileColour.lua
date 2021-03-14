local TileColour = {}

function TileColour.new(colour1, colour2, duration)
	local tileColour = {colour1 = colour1, colour2 = colour2, duration = duration, timeLeft = duration}
	return tileColour
end

function TileColour.update(tileColour, dt)
	tileColour.timeLeft = math.max(tileColour.timeLeft - dt, 0)
end

function TileColour.draw(tileColour, tile, camera)
	if tile.visible then
		Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
			local ratio = tileColour.timeLeft/tileColour.duration
			local colour = Misc.blendColours(tileColour.colour2, tileColour.colour1, ratio)
			love.graphics.setColor(colour)
			love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
		end)
	end
end

function TileColour.drawColourOnTile(colour, tile, camera)
	Camera.drawTo(camera, tile.x, tile.y, function(drawX, drawY)
		love.graphics.setColor(colour)
		love.graphics.rectangle("fill", drawX - camera.tileDims[1]/2, drawY - camera.tileDims[2]/2, camera.tileDims[1], camera.tileDims[2])
	end)
end

return TileColour