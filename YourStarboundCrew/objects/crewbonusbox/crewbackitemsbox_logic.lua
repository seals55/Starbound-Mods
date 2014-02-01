function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)
	local math = math
	local seed = world.day() + math.ceil(world.time() * 1000000)
	math.randomseed(seed)

	entity.smash()
	
	local backitemTable = {
		"batterypackAAback",
		"batwingsback",
		"crayonback",
		"crystalpackback",
		"dangerbarrelback",
		"eyeback",
		"lanternstickback",
		"oxygentank",
		"parachutepackback",
		"rainbowcapeback",
		"shortcapeback",
		"simplecapeback",
		"slimcapeback",
		"spacetankback",
		"toxicflowerback",
		"toxicwasteback",
		"turtleshellback",
		"naturecapeback",
		"fairyback",
		"hikerback",
		"hunterback",
		"pilotback",
		"pirateback",
		"wizardback",
		"pixelherodemoback"
	}
	local randomBackItemSeed = math.random(1,#backitemTable)
	local backitemloot = backitemTable[randomBackItemSeed]
	
	local lootTable = {
		{ ["item"]=backitemloot, 	 ["chance"]=95, ["amount"]=1, ["name"]="ore" }
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
		
		return { "ShowPopup", { message = "Woo, new clothes!" } }
	end
	
	return { "ShowPopup", { message = "I got an empty chest...?" } }
end