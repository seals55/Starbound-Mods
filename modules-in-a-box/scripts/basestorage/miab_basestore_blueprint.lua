blueprint = {}
debug_mode = false -- plot unneccessary to log

function blueprint.Init(boundsSize)
	-- Blueprint functions for base scanning and printing
	blueprint.optionsTable = {}

	-- All materials used are stored and given a numerical id
	blueprint.blocksTable = {}
	blueprint.nextBlockId = 1

	-- The actual layout of the blocks
	blueprint.layoutTableBackground = {}
	blueprint.layoutTableForeground = {}

	-- The placement of objects
	blueprint.objectTable = {}

	-- The actual layout of the items
	blueprint.accquiredItemsTable = {} -- stores how many items of each type have been hoovered up
	blueprint.requiredItemsTable = {} -- stores how many items of each type are needed by the blueprint

	-- A copy of the config table, so it doesn't go out of scope
	blueprint.configTable = {}

	-- A copy of the bounding box size, for print previewing
	blueprint.boundingBoxSize = copyTable(boundsSize)
end

------------------------------------------------------------------------------------
-- Config
------------------------------------------------------------------------------------
function blueprint.addFinalOptions(args)
	if (args.useInventory ~= nil) then
		blueprint.optionsTable.useInventory = args.useInventory
	end
end
------------------------------------------------------------------------------------
-- blocksTable
------------------------------------------------------------------------------------
-- Get the id for a given material name
function blueprint.blockId(matName)
	if matName == nil then
		return nil
	end

	local id = blueprint.blocksTable[matName]

	if id == nil then
		blueprint.blocksTable[matName] = blueprint.nextBlockId
		id = blueprint.nextBlockId
		blueprint.nextBlockId = blueprint.nextBlockId + 1
	end

	return id
end

-- Get the material name for a given id
function blueprint.materialFromId(id)
	for _name, _id in pairs(blueprint.blocksTable) do
		if _id == id then
			return _name
		end
	end

	return nil
end
------------------------------------------------------------------------------------
-- layoutTables
------------------------------------------------------------------------------------
-- Set the block id for a given material and position
function blueprint.setBlock(x, y, matName, layer)
	if layer == "background" then
		if blueprint.layoutTableBackground[y] == nil then
			blueprint.layoutTableBackground[y] = {}
		end
		blueprint.layoutTableBackground[y][x] = blueprint.blockId(matName)
	elseif layer == "foreground" then
		if blueprint.layoutTableForeground[y] == nil then
			blueprint.layoutTableForeground[y] = {}
		end
		blueprint.layoutTableForeground[y][x] = blueprint.blockId(matName)
	end
end

-- Get the material name of the block at a given position
function blueprint.getBlock(x, y, layer)
	local id = nil
	if layer == "background" then
		if blueprint.layoutTableBackground[y] ~= nil then
			id = blueprint.layoutTableBackground[y][x]
		end
	elseif layer == "foreground" then
		if blueprint.layoutTableForeground[y] ~= nil then
			id = blueprint.layoutTableForeground[y][x]
		end
	else
		return nil
	end

	if id == nil then
		return nil
	end

	local matName = blueprint.materialFromId(id)
	
	return matName
end
------------------------------------------------------------------------------------
-- objectTables
------------------------------------------------------------------------------------
-- Store an obect at a given position
function blueprint.setObject(x, y, Id)
	-- init
	ObjectParameter_tbl = {};
	
	if (Id == nil) then
		blueprint.objectTable[y][x] = ObjectParameter_tbl
		return
	end

	-- read values from world
	ObjectParameter_tbl.Name = world.entityName(Id);
	ObjectParameter_tbl.Facing = world.callScriptedEntity(Id, "entity.direction")
	if ObjectParameter_tbl.Facing == nil then
		ObjectParameter_tbl.Facing = 1
	end
--	if (debug_mode) then world.logInfo(tostring(Id) .. ".Facing: " .. tostring(ObjectParameter_tbl.Facing)) end
	-- create entry
	if blueprint.objectTable[y] == nil then
		blueprint.objectTable[y] = {}
	end
	blueprint.objectTable[y][x] = ObjectParameter_tbl
end
------------------------------------------------------------------------------------
-- ItemInventoryTables
------------------------------------------------------------------------------------
-- Get the material name of the block at a given position
function blueprint.addItemsAccquired(Descriptor)
	-- Descriptor = {"Name",(int)Ammount}
	if Descriptor == nil then return nil end
	if Descriptor[1] == nil then return nil end
	
	if blueprint.accquiredItemsTable[Descriptor[1]] == nil then
		-- new item type
		blueprint.accquiredItemsTable[Descriptor[1]] = 0;
	end
	
	blueprint.accquiredItemsTable[Descriptor[1]] = blueprint.accquiredItemsTable[Descriptor[1]]+Descriptor[2];
	
	return Descriptor
end

function blueprint.addItemsRequired(Descriptor)
	-- Descriptor = {"Name",(int)Ammount}
	if Descriptor == nil then return nil end
	if Descriptor[1] == nil then return nil end
	
	if blueprint.requiredItemsTable[Descriptor[1]] == nil then
		-- new item type
		blueprint.requiredItemsTable[Descriptor[1]] = 0;
	end
	
	blueprint.requiredItemsTable[Descriptor[1]] = blueprint.requiredItemsTable[Descriptor[1]]+Descriptor[2];
	
	return Descriptor	
end

function blueprint.haveItemsInTable(Descriptor,Itemtable)
	-- Descriptor = {"Name",(int)Ammount}
	if Descriptor == nil then return nil end
	if Descriptor[1] == nil then return nil end
	if Descriptor[2] == nil then return nil end
	
	-- check if that item is in the table
	local required_item_found = false
	-- check if the required item is there and if we have enough of it
	for _AC_name, _AC_nr in pairs(Itemtable) do
		AC_Descriptor = {}
		AC_Descriptor[1] = _AC_name
		AC_Descriptor[2] = _AC_nr
		if      (blueprint.strcmp_item_other(Descriptor[1], AC_Descriptor[1]))
			and (AC_Descriptor[2] >= Descriptor[2]) then
			-- this required item is there and we have enough of it
			required_item_found = true;
		end
	end
	
	-- if false at least one item type or quantity is missing
	return required_item_found;
end

function blueprint.removeItemsFromTable(Descriptor,Itemtable)
	-- Descriptor = {"Name",(int)Ammount}
	-- this function removes the Descriptor item from the table
	-- OR it removes a similary named item if it can find that
	-- "glas" <-> "glasmaterial" problem
	if Descriptor == nil then return nil end
	if Descriptor[1] == nil then return nil end
	if Descriptor[2] == nil then return nil end
	
	local required_item_found = false
	-- check if the required item is there and if we have enough of it
	local Similar_Descriptor = {};
	for _AC_name, _AC_nr in pairs(Itemtable) do
		Similar_Descriptor = {}
		Similar_Descriptor[1] = _AC_name
		Similar_Descriptor[2] = _AC_nr
		if      (blueprint.strcmp_item_other(Descriptor[1], Similar_Descriptor[1]))
			and (Similar_Descriptor[2] >= Descriptor[2]) then
			-- this required item is there and we have enough of it
			Itemtable[Similar_Descriptor[1]] = Itemtable[Similar_Descriptor[1]] - Descriptor[2]
			-- if last item has been removed
			if(Itemtable[Similar_Descriptor[1]] == 0) then
				-- delete entry
				Itemtable[Similar_Descriptor[1]] = nil;
			end
			required_item_found = true;
		end
	end
	
	-- if false at least one item type or quantity is missing
	return required_item_found;-- bool
end

function blueprint.Check_if_Required_items_have_been_Acquired()
	-- check if we hoovered up everything we need
	local required_item_found = false
	local RC_Descriptor = {}
	local AC_Descriptor = {}
	for _RC_name, _RC_nr in pairs(blueprint.requiredItemsTable) do		
		RC_Descriptor = {}
		RC_Descriptor[1] = _RC_name
		RC_Descriptor[2] = _RC_nr
		required_item_found = false -- default
		-- check if the required item is there and if we have enough of it
		for _AC_name, _AC_nr in pairs(blueprint.accquiredItemsTable) do
			AC_Descriptor = {}
			AC_Descriptor[1] = _AC_name
			AC_Descriptor[2] = _AC_nr
			if      (blueprint.strcmp_item_other(RC_Descriptor[1], AC_Descriptor[1]))
				and (AC_Descriptor[2] >= RC_Descriptor[2]) then
					-- this required item is there and we have enough of it
					required_item_found = true;
			end
		end
		if not(required_item_found) then
			-- at least one item type or quantity is missing
			return false
		end
	end
	-- no item was missing
	return true
end
------------------------------------------------------------------------------------
-- Hoover
------------------------------------------------------------------------------------
function blueprint.SpitOutATable(Itemtable)
--if(debug_mode ) then world.logInfo("Blueprint state at START of SpitOutATable") end
--if(debug_mode ) then  blueprint.logDump_Items() end
	local To_be_spit_out_Descriptors = {};
	local Counter_To_be_spit_out_Descriptors = 0;
	local Descriptor = {}
	for _Item_name, _Item_nr in pairs(Itemtable) do		
		Descriptor = {}
		Descriptor[1] = _Item_name
		Descriptor[2] = _Item_nr
		if (blueprint.haveItemsInTable(Descriptor,Itemtable)) then
			-- yes it could be removed from the stack
			-- add it to the stack of things to be spit out
			Counter_To_be_spit_out_Descriptors = Counter_To_be_spit_out_Descriptors+1;
			To_be_spit_out_Descriptors[Counter_To_be_spit_out_Descriptors] = {};
			To_be_spit_out_Descriptors[Counter_To_be_spit_out_Descriptors] = Descriptor;
		end
	end
	
	-- spit out what is not needed
	local Spit_out_Descriptor = {}
	if (Counter_To_be_spit_out_Descriptors > 0) then
		Spit_out_Descriptor = {}
		for _counter = 1, Counter_To_be_spit_out_Descriptors, 1 do
			Spit_out_Descriptor = To_be_spit_out_Descriptors[_counter];
			if (Spit_out_Descriptor ~= nil) then
				if (blueprint.removeItemsFromTable(Spit_out_Descriptor,Itemtable)) then
					-- it has been removed from the stack
--if(debug_mode ) then world.logInfo("Excess Item Spawned: " .. Spit_out_Descriptor[1] .. " " .. Spit_out_Descriptor[2]) end
					if(world.spawnItem(Spit_out_Descriptor[1], self.miab.pos_to_spit_out_unplaceables, Spit_out_Descriptor[2])) then
						--Done = false -- we still could spit out something in this run							
					end
				end
			end
		end
	end
if(debug_mode ) then  world.logInfo("Blueprint state at END of SpitOutATable") end
if(debug_mode ) then  blueprint.logDump_Items() end
end

function blueprint.SpitOutUndigestables()
if(debug_mode ) then  world.logInfo("Blueprint state at START of SpitOutUndigestables") end
if(debug_mode ) then  blueprint.logDump_Items() end

	-- we run this only one time and hope it works.
	-- if it would hang i woudnt know how to recover anyway.
	-- if you want to run it multiple times comment all the lines
	-- containing "Done" in again.
	-- local Done = true
	
	-- check if we hoovered something that we dont need
	local To_be_spit_out_Descriptors = {};
	local Counter_To_be_spit_out_Descriptors = 0;
	local AC_Descriptor = {}
	local RC_Descriptor = {}
	local Excess_Descriptor = {}
	local acquired_item_is_not_required = true
	
	for _AC_name, _AC_nr in pairs(blueprint.accquiredItemsTable) do
		AC_Descriptor = {}
		AC_Descriptor[1] = _AC_name
		AC_Descriptor[2] = _AC_nr
		
		acquired_item_is_not_required = true
		for _RC_name, _RC_nr in pairs(blueprint.requiredItemsTable) do		
			RC_Descriptor = {}
			RC_Descriptor[1] = _RC_name
			RC_Descriptor[2] = _RC_nr
			if blueprint.strcmp_item_other(_AC_name, _RC_name) then
				-- acquired item name is among requirements
				acquired_item_is_not_required = false;
				if(RC_Descriptor[2] < AC_Descriptor[2]) then
				-- we have acquired more then are required
					-- spit the exess out
					-- Excess_Descriptor = {}
					Excess_Descriptor[1] = _AC_name
					Excess_Descriptor[2] = _AC_nr - _RC_nr
					if (blueprint.haveItemsInTable(Excess_Descriptor,blueprint.accquiredItemsTable)) then
						-- yes it could be removed from the stack
						-- add it to the stack of things to be spit out
						Counter_To_be_spit_out_Descriptors = Counter_To_be_spit_out_Descriptors+1;
						To_be_spit_out_Descriptors[Counter_To_be_spit_out_Descriptors] = Excess_Descriptor;
					end
				end
			end
		end
		if (acquired_item_is_not_required) then
		-- item name could not be found in the required list
			if (blueprint.haveItemsInTable(AC_Descriptor,blueprint.accquiredItemsTable)) then
				-- it could be removed from the acquired list
				Counter_To_be_spit_out_Descriptors = Counter_To_be_spit_out_Descriptors+1;
				To_be_spit_out_Descriptors[Counter_To_be_spit_out_Descriptors] = AC_Descriptor;
			end
		end
	end
	
	-- spit out what is not needed
	local Spit_out_Descriptor = {}
	if (Counter_To_be_spit_out_Descriptors > 0) then
		Spit_out_Descriptor = {}
		for _counter = 1, Counter_To_be_spit_out_Descriptors, 1 do
			Spit_out_Descriptor = To_be_spit_out_Descriptors[_counter];
			if (Spit_out_Descriptor ~= nil) then
				if (blueprint.removeItemsFromTable(Spit_out_Descriptor,blueprint.accquiredItemsTable)) then
					-- it has been removed from the stack
--if(debug_mode ) then world.logInfo("Excess Item Spawned: " .. Spit_out_Descriptor[1] .. " " .. Spit_out_Descriptor[2]) end
					if(world.spawnItem(Spit_out_Descriptor[1], self.miab.pos_to_spit_out_unplaceables, Spit_out_Descriptor[2])) then
						--Done = false -- we still could spit out something in this run							
					end
				end
			end
		end
	end
	
	-- not done if something still could be spit out in the last run
	--if (Done) then self.miab.cleanupStage = self.miab.cleanupStage + 1; end

if(debug_mode ) then world.logInfo("Blueprint state at END of SpitOutUndigestables") end
if(debug_mode ) then blueprint.logDump_Items() end
end
------------------------------------------------------------------------------------
-- Serialisation
------------------------------------------------------------------------------------
-- returns a table for immediate config use
function blueprint.toConfigTable()
	local tbl = {}
	
	tbl.boundingBoxSize	  = blueprint.boundingBoxSize
	tbl.optionsTable          = blueprint.optionsTable;
	
	tbl.nextBlockId           = blueprint.nextBlockId
	tbl.blocksTable           = blueprint.blocksTable
	tbl.layoutTableBackground = blueprint.layoutTableBackground
	tbl.layoutTableForeground = blueprint.layoutTableForeground
	
	tbl.objectTable           = blueprint.objectTable
	
	tbl.accquiredItemsTable   = blueprint.accquiredItemsTable
	tbl.requiredItemsTable    = blueprint.requiredItemsTable

	return { miab_basestore_blueprint = tbl }
end

-- populates the config table and points the relevant stuff at it
function blueprint.fromEntityConfig()
	blueprint.configTable = entity.configParameter("miab_basestore_blueprint", nil)

	if blueprint.configTable ~= nil then
		blueprint.boundingBoxSize	= blueprint.configTable.boundingBoxSize
		blueprint.optionsTable          = blueprint.configTable.optionsTable;
		
		blueprint.nextBlockId           = blueprint.configTable.nextBlockId
		blueprint.blocksTable           = blueprint.configTable.blocksTable
		blueprint.layoutTableBackground = blueprint.configTable.layoutTableBackground
		blueprint.layoutTableForeground = blueprint.configTable.layoutTableForeground
		
		blueprint.objectTable           = blueprint.configTable.objectTable
		
		blueprint.accquiredItemsTable   = blueprint.configTable.accquiredItemsTable
		blueprint.requiredItemsTable    = blueprint.configTable.requiredItemsTable

		for _mat, _id in pairs(blueprint.blocksTable) do
			blueprint.blocksTable[_mat] = tonumber(_id)
		end
		for _y, _tbl in pairs(blueprint.layoutTableBackground) do
			for _x, _id in pairs(_tbl) do
				blueprint.layoutTableBackground[_y][_x] = tonumber(_id)
			end
		end
		for _y, _tbl in pairs(blueprint.layoutTableForeground) do
			for _x, _id in pairs(_tbl) do
				blueprint.layoutTableForeground[_y][_x] = tonumber(_id)
			end
		end
		for _itemAC, _id in pairs(blueprint.accquiredItemsTable) do
			blueprint.accquiredItemsTable[_itemAC] = tonumber(_id)
		end
		for _itemRQ, _id in pairs(blueprint.requiredItemsTable) do
			blueprint.requiredItemsTable[_itemRQ] = tonumber(_id)
		end
	end
end
		
function blueprint.Dump_Rcp_JSON()
	-- see: http://jsonlint.com/ for json validation tool
	world.logInfo("-------------------------------------------")
	world.logInfo("Recipe config serialisation:")
	world.logInfo("-------------------------------------------")
	world.logInfo("\"miab_basestore_recipe\" : {")
	world.logInfo("\t\"requiredItemsTable\" : {")
	local L = blueprint.tablelength(blueprint.requiredItemsTable)
	local cur_L = 0
	for _name, _nr in pairs(blueprint.requiredItemsTable) do
		cur_L = cur_L+1
		if (cur_L == L)then
			-- last entry without comma
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_nr))
		else
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_nr) .. ",")
		end
	end
	world.logInfo("\t}")
	world.logInfo("}")
	world.logInfo("-------------------------------------------")
	world.logInfo("Recipe config serialisation ends")
	world.logInfo("-------------------------------------------")
end

function blueprint.Dump_Obj_JSON()
	-- see: http://jsonlint.com/ for json validation tool
	local L = 0;
	local L2 = 0;
	local L3 = 0;
	local cur_L = 0;
	local cur_L2 = 0;
	local cur_L3 = 0;
	
	world.logInfo("-------------------------------------------")
	world.logInfo("Blueprint config serialisation:")
	world.logInfo("-------------------------------------------")
	world.logInfo("\"miab_basestore_blueprint\" : {")
	world.logInfo("\t\"boundingBoxSize\" : [")
	world.logInfo("\t\t" .. tostring(blueprint.boundingBoxSize[1]) .. ", " .. tostring(blueprint.boundingBoxSize[2]))
	world.logInfo("\t],")
	world.logInfo("\t\"blocksTable\" : {")
	L = blueprint.tablelength(blueprint.blocksTable)
	cur_L = 0
	for _name, _id in pairs(blueprint.blocksTable) do
		cur_L = cur_L+1
		if (cur_L == L)then
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_id))
		else
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_id) .. ",")
		end
	end
	world.logInfo("\t},")
	world.logInfo("\t\"nextBlockId\" : " .. blueprint.nextBlockId .. ",")
	world.logInfo("\t\"layoutTableBackground\" : {")
	L = blueprint.tablelength(blueprint.layoutTableBackground)
	cur_L = 0
	for _y, _tbl in pairs(blueprint.layoutTableBackground) do
		world.logInfo("\t\t\"" .. tostring(_y) .. "\" : {")
		L2 = blueprint.tablelength(_tbl)
		cur_L2 = 0
		for _x, _id in pairs(_tbl) do
			cur_L2 = cur_L2+1
			if (cur_L2 == L2) then
				world.logInfo("\t\t\t\"" .. tostring(_x) .. "\" : " .. toJSON(_id))
			else
				world.logInfo("\t\t\t\"" .. tostring(_x) .. "\" : " .. toJSON(_id) .. ",")
			end
		end
		cur_L = cur_L+1
		if (cur_L == L) then
			world.logInfo("\t\t}")
		else
			world.logInfo("\t\t},")
		end
	end
	world.logInfo("\t},")
	world.logInfo("\t\"layoutTableForeground\" : {")
	L = blueprint.tablelength(blueprint.layoutTableForeground)
	cur_L = 0
	for _y, _tbl in pairs(blueprint.layoutTableForeground) do
		world.logInfo("\t\t\"" .. tostring(_y) .. "\" : {")
		L2 = blueprint.tablelength(_tbl)
		cur_L2 = 0
		for _x, _id in pairs(_tbl) do
			cur_L2 = cur_L2+1
			if (cur_L2 == L2) then
				world.logInfo("\t\t\t\"" .. tostring(_x) .. "\" : " .. toJSON(_id))
			else
				world.logInfo("\t\t\t\"" .. tostring(_x) .. "\" : " .. toJSON(_id) .. ",")
			end
		end
		cur_L = cur_L+1
		if (cur_L == L) then
			world.logInfo("\t\t}")
		else
			world.logInfo("\t\t},")
		end
	end
	world.logInfo("\t},")
	world.logInfo("\t\"objectTable\" : {")
	L = blueprint.tablelength(blueprint.objectTable)
	cur_L = 0
	for _y, _tbl in pairs(blueprint.objectTable) do
		world.logInfo("\t\t\"" .. tostring(_y) .. "\" : {")
		L2 = blueprint.tablelength(_tbl)
		cur_L2 = 0
		for _x, _objTbl in pairs(_tbl) do
			world.logInfo("\t\t\t\"" .. tostring(_x) .. "\" : {")
			L3 = blueprint.tablelength(_objTbl)
			cur_L3 = 0
			for _key, _val in pairs(_objTbl) do
				cur_L3 = cur_L3+1
				if (cur_L3 == L3) then
					world.logInfo("\t\t\t\t\"" .. tostring(_key) .. "\" : " .. toJSON(_val))
				else
					world.logInfo("\t\t\t\t\"" .. tostring(_key) .. "\" : " .. toJSON(_val) .. ",")
				end
			end
			cur_L2 = cur_L2 + 1
			if (cur_L2 == L2) then
				world.logInfo("\t\t\t}")
			else
				world.logInfo("\t\t\t},")
			end
		end
		cur_L = cur_L+1
		if (cur_L == L) then
			world.logInfo("\t\t}")
		else
			world.logInfo("\t\t},")
		end
	end
	world.logInfo("\t},")
	world.logInfo("\t\"optionsTable\" : {")
	L = blueprint.tablelength(blueprint.optionsTable)
	cur_L = 0
	for _key, _val in pairs(blueprint.optionsTable) do
		cur_L = cur_L+1
		if (cur_L == L) then
			world.logInfo("\t\t\"" .. tostring(_key) .. "\" : " .. toJSON(_val))
		else
			world.logInfo("\t\t\"" .. tostring(_key) .. "\" : " .. toJSON(_val) .. ",")
		end
	end
	world.logInfo("\t},")
	world.logInfo("\t\"accquiredItemsTable\" : {")
	L = blueprint.tablelength(blueprint.accquiredItemsTable)
	cur_L = 0
	for _name, _nr in pairs(blueprint.accquiredItemsTable) do
		cur_L = cur_L+1
		if (cur_L == L) then
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_nr))
		else
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_nr) .. ",")
		end
	end
	world.logInfo("\t},")
	world.logInfo("\t\"requiredItemsTable\" : {")
	L = blueprint.tablelength(blueprint.requiredItemsTable)
	cur_L = 0
	for _name, _nr in pairs(blueprint.requiredItemsTable) do
		cur_L = cur_L+1
		if (cur_L == L) then
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_nr))
		else
			world.logInfo("\t\t\"" .. tostring(_name) .. "\" : " .. toJSON(_nr) .. ",")
		end
	end
	world.logInfo("\t}")
	world.logInfo("}")
	world.logInfo("-------------------------------------------")
	world.logInfo("Blueprint config serialisation ends")
	world.logInfo("-------------------------------------------")
end

function toJSON(val)
	if type(val) == "boolean" then
		if val == true then
			return "true"
		end
		return "false"
	elseif type(val) == "number" then
		return tostring(val)
	elseif type(val) == "string" then
		return "\"" .. val .. "\""
	else
		return "Error: Not a basic type"
	end
end

------------------------------------------------------------------------------------
-- Debug Logging
------------------------------------------------------------------------------------
function blueprint.logDump()
	world.logInfo("+- Blueprint begins")
	world.logInfo("|")

	world.logInfo("+-+- Materials")
	world.logInfo("| |")
	for _id, _name in pairs(blueprint.blocksTable) do
		if _id ~= nil and _name ~= nil then
			world.logInfo("| +- " .. _id .. " : " .. _name)
		end
	end
	world.logInfo("|")

	world.logInfo("+-+- Background layout")
	world.logInfo("| |")
	for _y, _tbl in pairs(blueprint.layoutTableBackground) do
		for _x, _id in pairs(_tbl) do
			world.logInfo("| +- " .. _x .. ", " .. _y .. " : " .. _id)
		end
	end
	world.logInfo("|")

	world.logInfo("+-+- Foreground layout")
	world.logInfo("| |")
	for _y, _tbl in pairs(blueprint.layoutTableForeground) do
		for _x, _id in pairs(_tbl) do
			world.logInfo("| +- " .. _x .. ", " .. _y .. " : " .. _id)
		end
	end
	world.logInfo("|")

	world.logInfo("+-+- Object list")
	world.logInfo("| |")
	for _y, _tbl in pairs(blueprint.objectTable) do
		for _x, _objtbl in pairs(_tbl) do
			world.logInfo("| +- " .. _x .. ", " .. _y .. " : ")
			for _key, _val in pairs(_objtbl) do
				world.logInfo("| +-- " .. _key .. ", " .. _val)
			end
		end
	end
	world.logInfo("|")

	blueprint.logDump_Items();
end

function blueprint.logDump_Items()
	world.logInfo("+-+- Items Accquired List")
	world.logInfo("| |")
	for _name, _nr in pairs(blueprint.accquiredItemsTable) do
		world.logInfo("| +- " .. _name .. ", #:" .. _nr)
	end
	world.logInfo("|")
	
	world.logInfo("+-+- Items Required List")
	world.logInfo("| |")
	for _name, _nr in pairs(blueprint.requiredItemsTable) do
		world.logInfo("| +- " .. _name .. ", #:" .. _nr)
	end
	world.logInfo("|")

	world.logInfo("+- Blueprint ends")
end
------------------------------------------------------------------------------------
-- UTIL
------------------------------------------------------------------------------------
function blueprint.is_inside_BB (pos,BB)
	-- checks if pos x,y coordinates are inside the boundary box BB defined by x1,y1,x2,y2
	--[[
	if     (pos[1] >= self.miab.boundingBox[1])
	   and (pos[1] <= self.miab.boundingBox[3])
	   and (pos[2] >= self.miab.boundingBox[2])
	   and (pos[2] <= self.miab.boundingBox[4]) then
	   return true
   else
	   return false
   end
	]]
	if (pos[1] < BB[1]) then return false end
	if (pos[1] > BB[3]) then return false end
	if (pos[2] < BB[2]) then return false end
	if (pos[2] > BB[4]) then return false end

	return true
end

function blueprint.strcmp_item_other (item_name,other_thing_name)
	-- Problem worked around by this function:
	-- some items have a different name when placed then the item it spawns
	-- i.e. "glas" <-> "glasmaterial"

	if(item_name == other_thing_name) then
		-- direct match, easy.
		return true
	end
	
	return false
end

function blueprint.clearBlock(pos,layer)
	world.damageTiles({pos}, layer, pos, "crushing", 10000)
	
	-- hoover up the current blocks at once
	local bl = {pos[1]-1,pos[2]-1}
	local tr = {pos[1]+1,pos[2]+1}
	local SelfId = entity.id()
	local ItemDropIds = world.itemDropQuery(bl,tr)
	local Descriptor = {}
	
	if ItemDropIds then
		for ItemId_Nr, ItemDropId in pairs(ItemDropIds) do
			Descriptor = world.takeItemDrop(ItemDropId, SelfId);
			blueprint.addItemsAccquired(Descriptor);
		end
	end
end

function blueprint.tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

