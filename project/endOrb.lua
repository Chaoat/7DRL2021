local EndOrb = {}

function EndOrb.new(x, y, world)
	local endOrb = {character = Character.new(Body.new(x, y, world, 999, 999, 0, "character"), 0, Image.letterToImage("*", {0.6, 0.3, 0.1, 1}), "Shackle of the Devourer", "You expected it to be more ornate, but it is little more than a metallic orb resting within a pedestal of oak. Nevertheless, this must be your objective, lying as it does in the center of the Labyrinth. The techs told you all you had to do was approach it, and the orb would do the rest. They neglected to mention exactly what it was that the orb would be doing, but you are far too deep to begin worrying about such things.")}
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