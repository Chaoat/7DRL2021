local EndOrb = {}

function EndOrb.new(x, y, world)
	local endOrb = {character = Character.new(Body.new(x, y, world, 999, 999, 0, "character"), 0, Image.letterToImage("*", {0.6, 0.3, 0.1, 1}))}
	Body.anchor(endOrb.character.body)
	Body.setInvincible(endOrb.character.body)
	
	endOrb.character.body.destroyFunction = function(body)
		Game.nextLevel(globalGame)
	end
	
	table.insert(world.endOrbs, endOrb)
end

function EndOrb.updateOrbs(orbs, player)
	local i = #orbs
	local pBody = player.character.body
	while i > 0 do
		local orb = orbs[i]
		
		local dist = math.sqrt((orb.character.body.y - pBody.y)^2 + (orb.character.body.x - pBody.x)^2)
		if math.floor(dist) <= 1 then
			Body.destroy(orb.character.body)
		end
		
		if orb.character.body.destroy then
			table.remove(orbs, i)
		end
		i = i - 1
	end
end

return EndOrb