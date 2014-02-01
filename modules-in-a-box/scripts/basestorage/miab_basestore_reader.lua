function Read_Start(args)
	self.miab = {};
	-- store area to read
	self.miab.boundingBox = copyTable(args.AreaToScan);
	
	-- store placement of printer
	self.miab.Reader_Position = copyTable(args.Reader_Position)
	
	-- position where the blueprint (or currently printer) will be dropped after successfull read
	self.miab.Spawn_Printer_Item_Position = copyTable(args.Spawn_Printer_Item_Position)
	
	-- position where excess items are spit out again
	self.miab.pos_to_spit_out_unplaceables = copyTable(args.Spawn_Undigestables_Position)
	
	-- if true the scanner will not "Post Hoover" and try to collect all items that have been read
	-- the resulting blueprint will also not require any items to print out	
	self.miab.useInventory = args.useInventory
	
	-- if true plots an object file of the blueprint to the log
	self.miab.Plot_Object_JSON = args.Plot_Object_JSON;
	
	-- if true plots an recipe file of the blueprint to the log
	self.miab.Plot_Recipe_JSON = args.Plot_Recipe_JSON;
		
	-- hoover this area if not everything could be collected at once
	self.miab.Main_Hoover_BB = {};
	self.miab.Main_Hoover_BB[1] = {self.miab.boundingBox[1], self.miab.boundingBox[2]};
	self.miab.Main_Hoover_BB[2] = {self.miab.boundingBox[3], self.miab.boundingBox[4]};
	
	-- BB in which the hoover is active in the Post Hoover Stage
	self.miab.Post_Hoover_BB = {};
	self.miab.Post_Hoover_BB[1] = {args.Reader_Position[1]-5, args.Reader_Position[2]-5}
	self.miab.Post_Hoover_BB[2] = {args.Reader_Position[1]+5, args.Reader_Position[1]+5}
	
	self.miab.Blueprint_Animation_time_to_show = args.Length_of_BP_Animation_in_s --[s]
	
	-- reset the blueprint to blank (and store bounding box)
	local dist = world.distance({self.miab.boundingBox[3], self.miab.boundingBox[4]}, {self.miab.boundingBox[1], self.miab.boundingBox[2]})
	blueprint.Init({dist[1], dist[2]})
	
	-- flag to start printing
	self.miab.cleanupStage = 1
	
	self.miab.Blueprint_Animation_started = false;
end

function Read_Module()
	if (self.miab == nil) then return false; end -- not initialized
	
	if (self.miab.cleanupStage ~= 0) then
		-- main_threaded();
		if not(co) then
			co = coroutine.create(function () main_threaded(); end)
		end
		if (coroutine.status(co) == "suspended") then
			-- start thread
			coroutine.resume(co);
		elseif (coroutine.status(co) == "dead") then
			co = coroutine.create(function () main_threaded(); end)
		elseif (coroutine.status(co) == "running") then
			-- nothing
		end
	end
	
	return false; -- state machine not done yet
end

function main_threaded()
	if self.miab.cleanupStage == 1 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		if (set_green_animation) then set_green_animation() end
		scanBuilding()
	end
	if self.miab.cleanupStage == 3 then
-- WARNING : this stage needs to be placed BEFORE "destroyObjects" and "destroyBlocks"
-- phase so the thread can exit once. else this will remove everything from the blueprint
-- as nothing will have been deconstructed so far
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		if (set_green_animation) then set_green_animation() end
		Post_Destruction_scanBuilding()
		self.miab.cleanupStage = self.miab.cleanupStage + 1;
	end
	if self.miab.cleanupStage == 2 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
-- WARNING : this stage needs to be placed AFTER "Post_Destruction_scanBuilding"
-- phase so the thread can exit once.
		if (set_green_animation) then set_green_animation() end
		destroyObjects()
		destroyBlocks()
		self.miab.cleanupStage = self.miab.cleanupStage + 1;
	end
	if self.miab.cleanupStage == 4 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		if (set_green_animation) then set_green_animation() end
		collectItemDrops(self.miab.Main_Hoover_BB,false)
	end
	if self.miab.cleanupStage == 5 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
--blueprint.logDump_Items()
		Post_Hoover_Stage()
	end
	if self.miab.cleanupStage == 6 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
--blueprint.logDump_Items()
		if (set_green_animation) then set_green_animation() end
		blueprint.SpitOutUndigestables()
		self.miab.cleanupStage = self.miab.cleanupStage + 1
--blueprint.logDump_Items()
	end
	if self.miab.cleanupStage == 7 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		if (set_green_animation) then set_green_animation() end
		spawnPrinterItem()
		self.miab.cleanupStage = self.miab.cleanupStage + 1
	end
	if self.miab.cleanupStage == 8 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		if (set_green_animation) then set_green_animation() end
		Produce_JSON_Output()
		self.miab.cleanupStage = self.miab.cleanupStage + 1
	end
	if self.miab.cleanupStage == 9 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		Display_Blueprint_Animation_for_while()
	end
	if self.miab.cleanupStage == 10 then
if(debug_mode ) then world.logInfo("self.miab.cleanupStage: " .. self.miab.cleanupStage) end
		if (set_green_animation) then set_green_animation() end
		deinit_with_success()
	end
end

----- Reading State machine -----
-- access functions
function Is_In_Post_Hoover_Stage()
	if (self.miab ~= nil) then
		if (self.miab.cleanupStage == 5) then
			return true;
		end
	end
	return false;
end

-- workers
function scanBuilding()
	if self.miab.boundingBox == nil then
		deinit_with_error();
		return
	end
	
	local did_scan_anything_at_all = false;
	
	local dist = world.distance({self.miab.boundingBox[3], self.miab.boundingBox[4]}, {self.miab.boundingBox[1], self.miab.boundingBox[2]})
	local xMax = dist[1]
	local yMax = dist[2]
	if xMax < 1 or yMax < 1 then
if(debug_mode ) then world.logInfo("Bounding box too small: " .. xMax .. "," .. yMax)end
		deinit_with_error();
		return
	end
	
--[[
-- doesnt want to work ...	
	-- scan players
	local PlayerIds = world.playerQuery ({Read_Scan_CFG.boundingBox[1], Read_Scan_CFG.boundingBox[2]}, {Read_Scan_CFG.boundingBox[3], Read_Scan_CFG.boundingBox[4]})
	if PlayerIds then
		for i, PlayerId in pairs(PlayerIds) do
			if (debug_mode) then world.logInfo("Player inside scan area.") end
			deinit_with_error();
			return
		end
	end
	-- scan monsters
	local MonsterIds = world.monsterQuery ({Read_Scan_CFG.boundingBox[1], Read_Scan_CFG.boundingBox[2]}, {Read_Scan_CFG.boundingBox[3], Read_Scan_CFG.boundingBox[4]})
	if MonsterIds then
		for i, MonsterId in pairs(MonsterIds) do
			if (debug_mode) then world.logInfo("Monster inside scan area.") end
			deinit_with_error();
			return
		end
	end
	-- scan npcs
	local NPCIds = world.npcQuery ({Read_Scan_CFG.boundingBox[1], Read_Scan_CFG.boundingBox[2]}, {Read_Scan_CFG.boundingBox[3], Read_Scan_CFG.boundingBox[4]})
	if NPCIds then
		for i, NPCId in pairs(NPCIds) do
			if (debug_mode) then world.logInfo("NPC inside scan area.") end
			deinit_with_error();
			return
		end
	end
]]

	-- scan blocks
	local pos = nil
	local matName_back = nil
	local matName_fore = nil
	local Descriptor = {}
	for y = 0, yMax, 1 do
		for x = 0, xMax, 1 do
			pos = {self.miab.boundingBox[1] + x, self.miab.boundingBox[2] + y}
			matName_back = world.material(pos, "background")
			matName_fore = world.material(pos, "foreground")
			if (matName_back) then
				-- store in blueprint
				blueprint.setBlock(x, y, matName_back, "background")
				
				-- add requirement for this to blueprint
				Descriptor = {}
				Descriptor[1] = matsTable[matName_back]
				Descriptor[2] = 1
				if self.miab.useInventory == true then
					blueprint.addItemsAccquired(Descriptor)
					blueprint.addItemsRequired(Descriptor)
				end
				
				did_scan_anything_at_all = true;
			else
				-- store as scaffold location
				blueprint.setBlock(x, y, "miab_scaffold", "background")
			end
			
			if (matName_fore) then
				-- store in blueprint
				blueprint.setBlock(x, y, matName_fore, "foreground")
				
				-- add requirement for this to blueprint
				Descriptor = {}
				Descriptor[1] = matsTable[matName_fore]
				Descriptor[2] = 1
				if self.miab.useInventory == true then
					blueprint.addItemsAccquired(Descriptor)
					blueprint.addItemsRequired(Descriptor)
				end
				
				did_scan_anything_at_all = true;
			else
				-- store as scaffold location
				blueprint.setBlock(x, y, "miab_scaffold", "foreground")
			end
		end
	end

	-- scan objects
	local ObjectIds = world.objectQuery({self.miab.boundingBox[1], self.miab.boundingBox[2]}, {self.miab.boundingBox[3], self.miab.boundingBox[4]})
	if ObjectIds then
		for i, ObjectId in pairs(ObjectIds) do
			pos = world.entityPosition(ObjectId)
			dist = world.distance(pos, {self.miab.boundingBox[1], self.miab.boundingBox[2]})
			-- this if is needed as objects that overlap the BB but are not placed
			-- "at a block inside the BB" dont need to be copied			
			if (blueprint.is_inside_BB (pos,self.miab.boundingBox)) then
				-- store in blueprint
				blueprint.setObject(dist[1], dist[2], ObjectId)
				-- add requirement for this to blueprint
				Descriptor = {}
				Descriptor[1] = world.entityName(ObjectId)
				Descriptor[2] = 1
				--if self.miab.useInventory == true then
					blueprint.addItemsRequired(Descriptor)
				--end
				
				did_scan_anything_at_all = true;
			end
		end
	end

	if not (did_scan_anything_at_all) then
		deinit_with_error();
	else
		self.miab.cleanupStage = self.miab.cleanupStage + 1;
	end
end

function destroyObjects()
-- doesn't work for some reason, leave it as a placeholder for when there's a world.destroyObject() function or something equally useful
--[[ 
	local pos = {}
	for _y, _tbl in pairs(blueprint.objectTable) do
		for _x, _objTbl in pairs(_tbl) do
			pos = {self.miab.boundingBox[1] + _x, self.miab.boundingBox[2] + _y}
			world.placeMaterial(pos, "background", "concrete", nil, true)
			blueprint.clearBlock(pos, "background")
		end
	end
]]
end

function destroyBlocks()
	local dist = world.distance({self.miab.boundingBox[3], self.miab.boundingBox[4]}, {self.miab.boundingBox[1], self.miab.boundingBox[2]})
	local xMax = dist[1]
	local yMax = dist[2]
	local allClear = true
	local pos = {}

	for y = yMax, 0, -1 do
		for x = 0, xMax, 1 do
			pos = {self.miab.boundingBox[1] + x, self.miab.boundingBox[2] + y}
			blueprint.clearBlock(pos,"background");
			blueprint.clearBlock(pos,"foreground");

			if world.material(pos, "background") ~= nil then
				allClear = false
			end
			if world.material(pos, "foreground") ~= nil then
				allClear = false
			end
		end
	end

--[[
	if allClear == true then
		self.miab.cleanupStage = self.miab.cleanupStage + 1;
	end
]]
end

function Post_Destruction_scanBuilding()
	local dist = world.distance({self.miab.boundingBox[3], self.miab.boundingBox[4]}, {self.miab.boundingBox[1], self.miab.boundingBox[2]})
	local xMax = dist[1]
	local yMax = dist[2]
	if xMax < 1 or yMax < 1 then
if(debug_mode ) then world.logInfo("Bounding box too small: " .. xMax .. "," .. yMax)end
		deinit_with_error();
		return
	end
	
	-- scan blocks
	local pos = nil
	local matName_back = nil
	local matName_fore = nil
	local Descriptor = {}
	for y = 0, yMax, 1 do
		for x = 0, xMax, 1 do
			pos = {self.miab.boundingBox[1] + x, self.miab.boundingBox[2] + y}
			matName_back = world.material(pos, "background")
			matName_fore = world.material(pos, "foreground")
			if (matName_back ~= nil) then
				-- remove this block from blueprint
				blueprint.setBlock(x, y, nil, "background")
				-- remove requirements for this from blueprint
				Descriptor = {}
				Descriptor[1] = matName_back
				Descriptor[2] = 1
				blueprint.removeItemsFromTable(Descriptor,blueprint.requiredItemsTable)
			else
			end
			if (matName_back ~= nil) then
				-- remove this block from blueprint
				blueprint.setBlock(x, y, nil, "foreground")
				-- remove requirements for this from blueprint
				Descriptor = {}
				Descriptor[1] = matName_fore
				Descriptor[2] = 1
				blueprint.removeItemsFromTable(Descriptor,blueprint.requiredItemsTable)
			else
			end
		end
	end
	-- scan objects
	local ObjectIds = world.objectQuery({self.miab.boundingBox[1], self.miab.boundingBox[2]}, {self.miab.boundingBox[3], self.miab.boundingBox[4]})
	if ObjectIds then
		for i, ObjectId in pairs(ObjectIds) do
			pos = world.entityPosition(ObjectId)
			dist = world.distance(pos, {self.miab.boundingBox[1], self.miab.boundingBox[2]})
			-- this if is needed as objects that overlap the BB but are not placed
			-- "at a block inside the BB" dont need to be copied			
			if (blueprint.is_inside_BB (pos,self.miab.boundingBox)) then
				-- remove this object from blueprint
				blueprint.setObject(dist[1], dist[2], nil)
				-- remove requirements for this from blueprint
				Descriptor = {}
				Descriptor[1] = world.entityName(ObjectId)
				Descriptor[2] = 1
				blueprint.removeItemsFromTable(Descriptor,blueprint.requiredItemsTable)
			end
		end
	end
end

function collectItemDrops(BoundingBox, LoopUnlimitted)
	-- this should have to collect anything anymore,
	-- as we already did collect for every destroyed block.
	-- Anyway, just to be sure: hoover the whole area.
	local SelfId = entity.id();
	local ItemDropIds = world.itemDropQuery(BoundingBox[1],BoundingBox[2])
	local Descriptor = {};
	for i, ItemDropId in pairs(ItemDropIds) do
		Descriptor = world.takeItemDrop(ItemDropId, SelfId);
		blueprint.addItemsAccquired(Descriptor);
	end
	
	if not(LoopUnlimitted) then
		self.miab.cleanupStage = self.miab.cleanupStage + 1;
	end
end

function Post_Hoover_Stage()
	if (self.miab.useInventory) then
		-- Post Hoover stage
		-- In this stage the reader will hoover up anything
		-- that is thrown at it until it did hoover up all
		-- required items to build the blueprint.
		-- Sometimes that might not be possible, which is why
		-- "End_Post_Hoover_Stage()" can also be called 
		-- by activating the reader once more.
		-- The blueprint will then be created without the
		-- missing parts. The missing parts will not be printed later on.
		if not(blueprint.Check_if_Required_items_have_been_Acquired()) then
			-- hoover up in a small area around the reader
			-- until it is activated again
			if (set_yellow_animation) then set_yellow_animation() end
			collectItemDrops(self.miab.Post_Hoover_BB,true)
		else
			End_Post_Hoover_Stage();
		end
	else
		-- dont use inventory -> dont use post hoover also
		End_Post_Hoover_Stage();
	end
end

function End_Post_Hoover_Stage()
	if Is_In_Post_Hoover_Stage() then
		-- move to the next stage
		self.miab.cleanupStage = self.miab.cleanupStage + 1
	end
	return
end

function spawnPrinterItem()
	-- add final Option values to blueprint
	local BP_Options = {};
	BP_Options.useInventory = self.miab.useInventory;
	blueprint.addFinalOptions(BP_Options)
	
	-- spawn printer item
	local _configTbl = blueprint.toConfigTable()
--[[	local _sizeString = "[" .. tostring(blueprint.boundingBoxSize[1]) .. "x" .. tostring(blueprint.boundingBoxSize[2]) .. "]"
	_configTbl.description = "This device contains the blueprint for a " .. _sizeString .. " building"
	]]
	world.spawnItem("miab_basestore_printer", self.miab.Spawn_Printer_Item_Position, 1, _configTbl)
end

function Produce_JSON_Output()
	if (self.miab.Plot_Object_JSON) then
		blueprint.Dump_Obj_JSON();
	end
	if (self.miab.Plot_Recipe_JSON) then
		blueprint.Dump_Rcp_JSON();
	end
end

function Display_Blueprint_Animation_for_while()
	if (self.miab.Blueprint_Animation_started) then
		-- timer is already running
		if(os.time() >= self.miab.Blueprint_Animation_started_timer + self.miab.Blueprint_Animation_time_to_show) then
			-- timer ran out
			if (set_green_animation) then set_green_animation () end
			self.miab.Blueprint_Animation_started = false;
			self.miab.cleanupStage = self.miab.cleanupStage + 1
		end
	else
		if (set_blueprint_animation) then
			-- start animation
			set_blueprint_animation ()
			-- start timer
			self.miab.Blueprint_Animation_started_timer = os.time();
			self.miab.Blueprint_Animation_started = true
		else
			-- scanner did not define this. skip blueprint display
			self.miab.cleanupStage = self.miab.cleanupStage + 1
		end
	end
end

function deinit_with_error()
	blueprint.Init({0, 0}); -- reset blueprint
	self.miab.cleanupStage = 0; -- reset state
end

function deinit_with_success()
	blueprint.Init({0, 0}); -- reset blueprint
	self.miab.cleanupStage = 0; -- reset state
end