function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)
	local math = math
	local seed = world.day() + math.ceil(world.time() * 1000000)
	math.randomseed(seed)

	entity.smash()
	
	local oreTable = {
		"coalore",
		"coalore",
		"coalore",
		"coalore",
		"coalore",
		"coalore",
		"coalore",
		"ironore",
		"ironore",
		"ironore",
		"ironore",
		"ironore",
		"copperore",
		"silverore",
		"silverore",
		"silverore",
		"silverore",
		"goldore",
		"goldore",
		"goldore",
		"diamondore"
	}
	local randomOreSeed = math.random(1,#oreTable)
	local oreloot = oreTable[randomOreSeed]
	
	local lootTable = {
		{ ["item"]=oreloot, 	 ["chance"]=95, ["amount"]=math.random(20, 40), ["name"]="ore" }
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