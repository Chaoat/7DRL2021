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
	newItemEntry(1, "Bolt Caster", 15, Image.letterToImage("-", {0, 0.8, 0, 1}))
	newItemEntry(1, "Force Wave", 12, Image.letterToImage("*", {0.8, 0.8, 1, 1}))
	newItemEntry(1, "Hydrocarbon Explosive", 4, Image.letterToImage("o", {0.4, 0, 0, 1}))
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
	local chest = {character = Character.new(Body.new(x, y, world, 10, 100, 0, "character"), 0, Image.letterToImage("#", {0.2, 0.9, 0.9, 1}))}
	
	chest.character.body.destroyFunction = function(body)
		openChest(body.x, body.y, {1}, {1, 2}, world)
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
			TileColour.drawColourOnTile({0, 1, 1, 0.2}, item.body.tile, camera)
			love.graphics.setColor(1, 1, 1, 1)
			Image.drawImage(item.image, camera, item.body.x, item.body.y, item.angle)
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