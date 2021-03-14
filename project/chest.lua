local Chest = {}

local itemRarities = {}
local function newItemEntry(rarity, weaponName, quantity, itemImage)
	local entry = {rarity = rarity, weaponName = weaponName, quantity = quantity, image = itemImage}
	if not itemRarities[rarity] then
		itemRarities[rarity] = {}
	end
	table.insert(itemRarities[rarity], entry)
end
do --initItemRarities
	newItemEntry(1, "Bolt Caster", 16, Image.letterToImage("-", {0, 0.8, 0, 1}))
	newItemEntry(1, "Force Wave", 12, Image.letterToImage("*", {0.8, 0.8, 1, 1}))
	newItemEntry(1, "Hydrocarbon Explosive", 4, Image.letterToImage("o", {0.4, 0, 0, 1}))
	newItemEntry(1, "Emergency Thruster", 8, Image.letterToImage("^", {1, 0.7, 0, 1}))
	
	newItemEntry(2, "Matter Compressor", 12, Image.letterToImage(">", {0.2, 0.2, 0.2, 1}))
	newItemEntry(2, "Entropy Orb", 16, Image.letterToImage("Y", {0.8, 0, 0.8, 1}))
	newItemEntry(2, "Sanctuary Sphere", 4, Image.letterToImage("+", {0, 1, 1, 1}))
	
	newItemEntry(3, "Annihilator Cannon", 4, Image.letterToImage("=", {0.9, 0.8, 0.6, 1}))
end

local function newItem(x, y, itemEntry, world)
	local item = {body = Body.new(x, y, world, 1, 1, 0, "item"), weapon = itemEntry.weaponName, quantity = itemEntry.quantity, image = itemEntry.image, angle = 0}
	item.body.parent = item
	Body.impartForce(item.body, Random.randomBetweenPoints(2, 5), Random.randomBetweenPoints(0, 2*math.pi))
	item.body.friction = 2
	table.insert(world.items, item)
end

local function openChest(x, y, rarities, itemNumberRange, world)
	local possibleItems = {}
	for i = 1, #rarities do
		for j = 1, #itemRarities[i] do
			table.insert(possibleItems, itemRarities[i][j])
		end
	end
	
	local quantity = Misc.round(Random.randomBetweenPoints(itemNumberRange[1], itemNumberRange[2]))
	local itemsChosen = Random.nRandomFromList(possibleItems, quantity)
	
	for i = 1, #itemsChosen do
		newItem(x, y, itemsChosen[i], world)
	end
end

function Chest.new(x, y, world)
	local chest = {character = Character.new(Body.new(x, y, world, 10, 100, 0, "character"), 0, Image.letterToImage("#", {0.2, 0.9, 0.9, 1}), "Cargo Pod", "A temporally sealed chamber designed to open only in your presence, or in the presence of extreme firepower. Threaded with powerful charms, this box is invisible to The Devourer and his minions, so you needn't worry about your weapons being stolen. That said, opening the pod without shattering the charms is not an option given your current toolkit, and while the pods can be refilled they can not be replaced. The combined scientific might of your people is concentrated on developing weapons to assist the next Runner, so it would be best to keep a few of the pods intact for their use.\n\nEvery generation will unlock new weapons that can spawn in the pods, however the pods themselves will not be restored. What this amounts to is that you should not go out of your way to bust open all the pods on the level, as this will severely diminish your chances of complete victory.")}
	
	chest.character.body.destroyFunction = function(body)
		local rarities = {}
		for i = 1, world.itemLevel do
			rarities[i] = i
		end
		openChest(body.x, body.y, rarities, {2, 4}, world)
	end
	
	Body.anchor(chest.character.body)
	table.insert(world.chests, chest)
end

function Chest.updateChests(chests, player)
	local i = #chests
	local pBody = player.character.body
	while i > 0 do
		local chest = chests[i]
		
		local dist = math.sqrt((chest.character.body.y - pBody.y)^2 + (chest.character.body.x - pBody.x)^2)
		if math.floor(dist) <= 1 then
			Body.destroy(chest.character.body)
		end
		
		if chest.character.body.destroy then
			table.remove(chests, i)
		end
		i = i - 1
	end
end

function Chest.updateItems(items, dt)
	local i = #items
	while i > 0 do
		local item = items[i]
		item.angle = item.angle + dt*item.body.speed
		
		if item.body.destroy then
			table.remove(items, i)
		end
		
		i = i - 1 
	end
end

function Chest.drawItems(items, camera)
	for i = 1, #items do
		local item = items[i]
		if item.body.tile.visible then
			TileColour.drawColourOnTile({0, 1, 1, 0.5}, item.body.tile, camera)
			love.graphics.setColor(1, 1, 1, 1)
			Image.drawImageWithOutline(item.image, camera, item.body.x, item.body.y, item.angle, {0, 1, 1, 1}, Misc.oscillateBetween(2, 5, 0.5))
		end
	end
end

function Chest.getItemsOnTile(tile, player)
	for i = 1, #tile.bodies["item"] do
		local body = tile.bodies["item"][i]
		local item = body.parent
		
		Player.getWeapon(player, item.weapon, item.quantity)
		Body.destroy(body)
	end
end

return Chest