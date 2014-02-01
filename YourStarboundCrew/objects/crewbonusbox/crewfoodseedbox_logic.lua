function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)
	local math = math
	local seed = world.day() + math.ceil(world.time() * 1000000)
	math.randomseed(seed)

	entity.smash()
	
	local foodTable = {
		"bananaseed",
		"cornseed",
		"wheatseed",
		"boltbulbseed",
		"bonebooseed",
		"crystalplantseed",
		"feathercrownseed",
		"automatoseed",
		"avesmingoseed",
		"beakseedseed",
		"carrotseed",
		"chiliseed",
		"currentcornseed",
		"diodiaseed",
		"eggshootseed",
		"grapeseed",
		"kiwiseed",
		"neonmelonseed",
		"pearlpeaseed",
		"sugarcaneseed",
		"coralcreepseed"
	}
	local randomFoodSeed = math.random(1,#foodTable)
	local foodseed = foodTable[randomFoodSeed]
	
	local lootTable = {
		{ ["item"]=foodseed, 	 ["chance"]=95, ["amount"]=math.random(3, 8), ["name"]="Yummy Seed!" }
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