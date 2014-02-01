function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

	local math = math
	local seed = world.day() + math.ceil(world.time() * 1000000)
	math.randomseed(seed)

	entity.smash()
	
	local foodrecipeTable = {
		"batteredbanana-recipe",
		"bananacon-recipe",
		"roastbanana-recipe",
		"wartweedstew-recipe",
		"curriedbeakseed-recipe",
		"meatandmarrow-recipe",
		"oculemonstew-recipe",
		"stuffedautomato-recipe",
		"boltos-recipe",
		"boiledpearlpeas-recipe",
		"burger-recipe",
		"vegetablesoup-recipe",
		"coralcreepcurry-recipe",
		"saltsalad-recipe",
		"ricecake-recipe",
		"bananabread-recipe"
	}
	local randomFoodRecipe = math.random(1,#foodrecipeTable)
	local foodrecipe = foodrecipeTable[randomFoodRecipe]
	
	local lootTable = {
		{ ["item"]=foodrecipe, 	 ["chance"]=95, ["amount"]=1, ["name"]="A delicious recipe!" }
	}
	
	local reward = nil
	local lootName = nil
	local amount = 0
	local roll = math.random(0, 100)
	for i = 1, #lootTable do
		if(roll <= lootTable[i].chance) then
			reward = lootTable[i].item
			amount = lootTable[i].amount
			lootName = lootTable[i].name
			break
		end
	end
	
	if(reward ~= nil) then
		world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 2.0 }), amount)
		
		return { "ShowPopup", { message = "You won x" .. amount .. " " .. lootName .. "!" } }
	end
	
	return { "ShowPopup", { message = "I got an empty chest...?" } }
end