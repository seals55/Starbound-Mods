function Print_Init(args)
	
	self.miab = {};
	
	-- We build at the right of this object, which is 1 blocks right
	self.miab.pos = args.Writer_Position
	
	-- this is where all items that have not been placed
	-- (for whatever reason i.e. door doesnt fit in new building location)
	-- are spawned after construction and before the blueprint is destroyed
	self.miab.pos_to_spit_out_unplaceables = args.Spawn_Unplaceables_Position
	
	-- display bluegrid
	self.miab.buildingStage = 1
	-- next bluegrid execution is now
	self.miab.time_to = nil;
	self.miab.particleDelay = os.time() - 1
	
	self.miab.ScaffoldmatName = "glass"
	
	-- spawn initial main calculation thread
	co = coroutine.create(function () main_threaded(); end)
	
	self.miab.init = true;
end

function Print_Start(boundingBox)
	-- flag to start printing
	if self.miab.buildingStage < 3 then
		self.miab.buildingStage = 3
	end
end

function Print_Module()
	if (self.miab) then else return false; end -- not initialized
	if (self.miab.init) then else return false; end -- not initialized

 	if (self.miab.buildingStage ~= 0) then
		-- main_threaded();
		if (coroutine.status(co) == "suspended") then
			-- start thread
			coroutine.resume(co);
		elseif (coroutine.status(co) == "dead") then
			-- spawn a new main calculation thread
			co = coroutine.create(function () main_threaded(); end)
		elseif (coroutine.status(co) == "running") then
			-- nothing
		end
	end
	
	if self.miab.buildingStage == 8 then
		-- finished printing
		return true
	else
		-- NOT finished printing
		return false
	end
end

function PrintPreview(pos)
	if self.miab.printPreviewDirection == nil then
		self.miab.printPreviewDirection = -1
	end
	local timeToLive = 3
	local start
	if self.miab.printPreviewDirection == -1 then
		start = blueprint.boundingBoxSize[2]
	else
		start = 0
	end
	local x
	local ourSpeed = blueprint.boundingBoxSize[2] / timeToLive
	if self.miab.printPreviewDirection == -1 then
		world.spawnProjectile("miab_buildingcode_r", {pos[1] + 0.5, start + pos[2] + 0.5}, entity.id(), {0, self.miab.printPreviewDirection}, true, {speed = ourSpeed})
		world.spawnProjectile("miab_buildingcode_l", {blueprint.boundingBoxSize[1] + pos[1] + 0.5, start + pos[2] + 0.5}, entity.id(), {0, self.miab.printPreviewDirection}, true, {speed = ourSpeed})
	else
		world.spawnProjectile("miab_buildingcode_l", {pos[1] + 0.5, start + pos[2] + 0.5}, entity.id(), {0, self.miab.printPreviewDirection}, true, {speed = ourSpeed})
		world.spawnProjectile("miab_buildingcode_r", {blueprint.boundingBoxSize[1] + pos[1] + 0.5, start + pos[2] + 0.5}, entity.id(), {0, self.miab.printPreviewDirection}, true, {speed = ourSpeed})
	end
	for x = 1, blueprint.boundingBoxSize[1] - 1, 1 do
		world.spawnProjectile("miab_buildingcode", {x + pos[1] + 0.5, start + pos[2] + 0.5}, entity.id(), {0, self.miab.printPreviewDirection}, true, {speed = ourSpeed})
	end
	self.miab.printPreviewDirection = 0 - self.miab.printPreviewDirection
	return timeToLive
end

function main_threaded()
	if self.miab.buildingStage == 1 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- read the Blueprint to be build
		readBlueprint();
	end
	if self.miab.buildingStage == 2 then
		if (self.miab.time_to == nil) then self.miab.time_to = os.time() - 1 end
		if(os.time() >= self.miab.time_to) then
			if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
			-- Place clearance markers
			--[[
			local PB_Settings = {};
			PB_Settings.Override_Objects           = true; -- if handle objects at all
			PB_Settings.Mark_Foreground            = true; -- if place marker for foreground
			PB_Settings.Mark_Background            = true; -- if place marker for background
			Process_Blueprint(PB_Settings);
			]]
			self.miab.time_to = os.time() + PrintPreview({self.miab.pos[1], self.miab.pos[2]});
		end
	end
	if self.miab.buildingStage == 3 then
		self.miab.obstructionTable = {}
		self.miab.was_able_to_print_something_at_some_point = false;
		
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- Clearance check if we could build here.
		local PB_Settings = {};
		PB_Settings.Override_Objects           = true; -- if handle objects at all
		-- uncomment the next line if you want to test writing while standing in the object
		-- the initial check if something is in the boundary box will not be performed.
		PB_Settings.Clearance_Check_Entities   = true; -- if place marker for foreground
		PB_Settings.Clearance_Check_Foreground = true; -- if place marker for foreground
		PB_Settings.Clearance_Check_Background = true; -- if place marker for background
		PB_Settings.Deconstruct_on_Fail        = true; -- if place marker for objects
		PB_Settings.Continue_on_sucess         = true; -- switch to next state machine state if done
		Process_Blueprint(PB_Settings);
	end
	if self.miab.buildingStage == 4 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- Place Foreground and Background blocks and scaffold
		local PB_Settings = {};
		PB_Settings.Override_Objects           = true; -- if handle objects at all
		PB_Settings.Place_Foreground           = true; -- if write to foreground
		PB_Settings.Place_Background           = true; -- if write to background
		PB_Settings.Place_Foreground_scaffold  = true; -- if write to foreground
		PB_Settings.Place_Background_scaffold  = true; -- if write to background
		-- as blocks dont drop anymore block placement never requires item
		--PB_Settings.Place_Requires_Item        = true and (blueprint.optionsTable.useInventory); -- if items to be places must reside in accquiredItemsTable
		PB_Settings.Continue_on_sucess         = true; -- switch to next state machine state if done
		PB_Settings.Continue_if_placement_gets_stuck = true -- if we could initialy build, but later on reach a point where we cant build anymore but still have done == false (for whatever reason) we dont loop infinity, but just continue
		PB_Settings.Deconstruct_on_nothing_could_be_printed = true; -- if triing to print in air so we dont get any anchor this will catch it
		Process_Blueprint(PB_Settings);
	end
	if self.miab.buildingStage == 5 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- Remove foreground and background scaffold
		local PB_Settings = {};
		PB_Settings.Override_Objects           = true; -- if handle objects at all
		PB_Settings.Remove_Foreground_scaffold = true; -- if write to foreground
		PB_Settings.Remove_Background_scaffold = true; -- if write to background
		PB_Settings.Place_Requires_Item        = false; -- if items to be places must reside in accquiredItemsTable
		PB_Settings.Continue_on_sucess         = true; -- switch to next state machine state if done
		Process_Blueprint(PB_Settings);
	end
	if self.miab.buildingStage == 6 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- Place Objects
		local PB_Settings = {};
		PB_Settings.Override_Background        = true; -- if handle background at all
		PB_Settings.Override_Foreground        = true; -- if handle foreground at all
		PB_Settings.Place_Objects              = true; -- if write objects
		PB_Settings.Place_Requires_Item        = true and (blueprint.optionsTable.useInventory); -- if items to be places must reside in accquiredItemsTable
		PB_Settings.Continue_on_sucess         = true; -- switch to next state machine state if done
		Process_Blueprint(PB_Settings);
	end
	if self.miab.buildingStage == 7 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- Spit out what was not needed for construction
		blueprint.SpitOutATable(blueprint.accquiredItemsTable)
		self.miab.buildingStage = self.miab.buildingStage +1;
	end
	if self.miab.buildingStage == 8 then
		-- WARNING state nr. 8 is considered the last one in "Print_Module()"
		-- if you renumber something above you also need to change the last state in that function!
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- ended with a successfull print
		--KillSelf();
	end
	if self.miab.buildingStage == 255 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- could not print here -> dropping self as item
		-- Deconstruct();
		FloatObstructed()
		self.miab.buildingStage = 2
	end
	if self.miab.buildingStage == 256 then
		if (debug_mode) then world.logInfo({"self.miab.buildingStage == ",self.miab.buildingStage}) end
		-- could not print here -> dropping self as item
		-- Deconstruct();
		FloatUnanchored()
		self.miab.buildingStage = 2
	end
end

function readBlueprint()
	blueprint.fromEntityConfig()
	if (debug_mode) then world.logInfo("Blueprint Status after accquiring it:") end
	--blueprint.logDump()
	if (blueprint.optionsTable.useInventory == false) and (blueprint.tablelength(blueprint.accquiredItemsTable) == 0) then
		local matName
		for _y, _tbl in pairs(blueprint.layoutTableBackground) do
			for _x, _id in pairs(_tbl) do
				matName = blueprint.materialFromId(_id)
				blueprint.addItemsAccquired({matsTable[matName], 1})
			end
		end
		for _y, _tbl in pairs(blueprint.layoutTableForeground) do
			for _x, _id in pairs(_tbl) do
				matName = blueprint.materialFromId(_id)
				blueprint.addItemsAccquired({matsTable[matName], 1})
			end
		end
		for _y, _tbl in pairs(blueprint.objectTable) do
			for _x, ObjectParameter_tbl in pairs(_tbl) do
				matName = ObjectParameter_tbl.Name;
				blueprint.addItemsAccquired({matName, 1})
			end
		end
	end
	self.miab.did_read_blueprint = true
	self.miab.buildingStage = self.miab.buildingStage + 1;
end

function Process_Blueprint(args)
--[[
	args.Override_Background -- if handle background at all
	args.Override_Foreground -- if handle foreground at all
	args.Override_Objects    -- if handle objects at all
	
	args.Place_Foreground -- if write to foreground
	args.Place_Background -- if write to background
	args.Place_Objects -- if write objects
	args.Place_Requires_Item -- if items to be places must reside in accquiredItemsTable
	
	args.Place_Foreground_scaffold -- if scaffold is to be placed on foreground
	args.Place_Background_scaffold -- if scaffold is to be placed on background
	
	args.Clearance_Check_Entities -- check if entities exist in locations where we want to build
	args.Clearance_Check_Foreground -- check if foreground blocks exist in locations where we want to build
	args.Clearance_Check_Background -- check if background blocks exist in locations where we want to build
	args.Clearance_Check_Objects -- check if objects exist in locations where we want to build
	
	args.Mark_Foreground -- if place marker for foreground
	args.Mark_Background -- if place marker for background
	args.Mark_Objects -- if place marker for objects
	
	args.Remove_Foreground_scaffold -- if scaffold is to be removed from foreground
	args.Remove_Background_scaffold -- if scaffold is to be removed from background
	
	args.Deconstruct_on_nothing_could_be_printed -- if triing to print in air so we dont get any anchor this will catch it
	args.Deconstruct_on_Fail -- if this object is destroy if this call doesnt succeed in the first call
	args.Continue_on_sucess -- switch to next state machine state if done
]]
	local Done = true;
	local matName = nil;
	local wpos = {};
	
	local anything_could_be_printed_this_run = false;
	
	local Nr_EntityIDs = nil;
	local EntityIDs = {};
	local cur_ent_Type = nil;
	
	-- entities clearance check
	if (args.Clearance_Check_Entities) then
		-- we can use the background table as every x,y coordinate is populated at least with a scaffold
		Nr_EntityIDs = 0;
		for _y, _tbl in pairs(blueprint.layoutTableBackground) do
			for _x, _id in pairs(_tbl) do
				wpos = { self.miab.pos[1] + _x, self.miab.pos[2] + _y }
				EntityIDs = world.entityQuery(wpos, wpos)
				for i, EntityID in pairs(EntityIDs) do
					if (EntityID ~= entity.id()) and (entityInOurBox(EntityID)) then
						-- "player","monster","object","itemdrop","projectile","plant","plantdrop","effect","npc"
						cur_ent_Type = world.entityType(EntityID)
						if (   (cur_ent_Type == "player")
							or (cur_ent_Type == "monster")
							or (cur_ent_Type == "npc")
							--or (cur_ent_Type == "plant")
							or (cur_ent_Type == "object")
							) then
							Nr_EntityIDs = Nr_EntityIDs+1;
							self.miab.obstructionTable[EntityID] = true
						end
					end
				end				
			end
		end
		if (Nr_EntityIDs > 0) then
			-- there are entities blocking placement
			Done = false;
		end
	end
	
	-- background all in one
	if not (Override_Background) then
		for _y, _tbl in pairs(blueprint.layoutTableBackground) do
			for _x, _id in pairs(_tbl) do
				matName = blueprint.materialFromId(_id)
				wpos = { self.miab.pos[1] + _x, self.miab.pos[2] + _y }
				if matName ~= nil then
					-- clearance check
					if(args.Clearance_Check_Background) then
						if world.material(wpos, "background") ~= nil then
							-- world block is not empty
							Done = false;
						end
					end
					-- place
					if (args.Place_Background) then
						EntityIDs = world.entityQuery(wpos, wpos)
						Nr_EntityIDs = 0;
						for i, EntityID in pairs(EntityIDs) do
							if (EntityID ~= entity.id()) and (entityInOurBox(EntityID)) then
								-- "player","monster","object","itemdrop","projectile","plant","plantdrop","effect","npc"
								cur_ent_Type = world.entityType(EntityID)
								if (   (cur_ent_Type == "player")
									or (cur_ent_Type == "monster")
									or (cur_ent_Type == "npc")
									--or (cur_ent_Type == "plant")
									or (cur_ent_Type == "object")
									) then
									Nr_EntityIDs = Nr_EntityIDs+1;
									self.miab.obstructionTable[EntityID] = true
								end
							end
						end
						if not (Nr_EntityIDs > 0) then
							if (matName ~= "miab_scaffold") then
								if world.material(wpos, "background") ~= matName then
									-- world block is not equal blueprint block
									if (args.Place_Requires_Item)then
										-- check if we have that item
										if (blueprint.haveItemsInTable({matsTable[matName],1},blueprint.accquiredItemsTable)) then
											-- try to place
											if(world.placeMaterial(wpos, "background", matName))then
												-- was placed -> remove from stash
												anything_could_be_printed_this_run = true;
												blueprint.removeItemsFromTable({matsTable[matName],1},blueprint.accquiredItemsTable)
											else
												-- coudn`t place
												Done = false;
											end
										else
											-- we dont have that item
										end
									else
										-- try to place
										if (world.placeMaterial(wpos, "background", matName)) then
											-- was placed -> remove from stash
											anything_could_be_printed_this_run = true;
											blueprint.removeItemsFromTable({matsTable[matName],1},blueprint.accquiredItemsTable)
										else
											-- coudn`t place
											Done = false;
										end
									end
								end
							else
								if(args.Place_Background_scaffold) then
									-- place scaffold
									if world.material(wpos, "background") ~= self.miab.ScaffoldmatName then
										if (world.placeMaterial(wpos, "background", self.miab.ScaffoldmatName)) then
											anything_could_be_printed_this_run = true;
										else
											-- coudn`t place
											Done = false;
										end
									end
								end
							end
						end
					end
					-- mark
--[[
					if(args.Mark_Background)then
						if (matName ~= "miab_scaffold") then
							if world.material(wpos, "background") ~= nil then
								-- world block is not empty
								world.spawnProjectile("miab_marker_occupied_block",wpos);
							else
								world.spawnProjectile("miab_marker_to_be_printed_block",wpos);
							end
						end
					end
]]
					-- remove scaffold
					if(args.Remove_Background_scaffold)then
						if (matName == "miab_scaffold") then
							-- place scaffold
							if world.material(wpos, "background") == self.miab.ScaffoldmatName then
								blueprint.clearBlock(wpos,"background");
								if world.material(wpos, "background") ~= nil then
									Done = false
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- foreground all in one
	if not (Override_Foreground) then
		for _y, _tbl in pairs(blueprint.layoutTableForeground) do
			for _x, _id in pairs(_tbl) do
				matName = blueprint.materialFromId(_id)
				wpos = { self.miab.pos[1] + _x, self.miab.pos[2] + _y }
				if matName ~= nil then
					-- clearance check
					if(args.Clearance_Check_Foreground) then
						if world.material(wpos, "foreground") ~= nil then
							-- world block is not empty
							Done = false;
						end
					end
					-- place
					if(args.Place_Foreground)then
						EntityIDs = world.entityQuery(wpos, wpos)
						Nr_EntityIDs = 0;
						for i, EntityID in pairs(EntityIDs) do
							if (EntityID ~= entity.id()) and (entityInOurBox(EntityID)) then
								-- "player","monster","object","itemdrop","projectile","plant","plantdrop","effect","npc"
								cur_ent_Type = world.entityType(EntityID)
								if (   (cur_ent_Type == "player")
									or (cur_ent_Type == "monster")
									or (cur_ent_Type == "npc")
									--or (cur_ent_Type == "plant")
									or (cur_ent_Type == "object")
									) then
									Nr_EntityIDs = Nr_EntityIDs+1;
									self.miab.obstructionTable[EntityID] = true
								end
							end
						end
						if not (Nr_EntityIDs > 0) then
							if (matName ~= "miab_scaffold") then
								if world.material(wpos, "foreground") ~= matName then
									-- world block is not equal blueprint block
									if (args.Place_Requires_Item)then
										-- check if we have that item
										if (blueprint.haveItemsInTable({matsTable[matName],1},blueprint.accquiredItemsTable)) then
											-- try to place
											if(world.placeMaterial(wpos, "foreground", matName))then
												-- was placed -> remove from stash
												anything_could_be_printed_this_run = true;
												blueprint.removeItemsFromTable({matsTable[matName],1},blueprint.accquiredItemsTable)
											else
												-- coudn`t place
												Done = false;
											end
										else
											-- we dont have that item
										end
									else
										-- try to place
										if (world.placeMaterial(wpos, "foreground", matName)) then
											-- was placed -> remove from stash
											anything_could_be_printed_this_run = true;
											blueprint.removeItemsFromTable({matsTable[matName],1},blueprint.accquiredItemsTable)
										else
											-- coudn`t place
											Done = false;
										end
									end
								end
							else
								if(args.Place_Foreground_scaffold) then
									-- place scaffold
									if world.material(wpos, "foreground") ~= self.miab.ScaffoldmatName then
										if (world.placeMaterial(wpos, "foreground", self.miab.ScaffoldmatName)) then
											anything_could_be_printed_this_run = true;
										else
											-- coudn`t place
											Done = false;
										end
									end
								end
							end
						end
					end
					-- mark
--[[
					if(args.Mark_Foreground)then
						if (matName ~= "miab_scaffold") then
							if world.material(wpos, "foreground") ~= nil then
								-- world block is not empty
								world.spawnProjectile("miab_marker_occupied_block",wpos);
							else
								-- world block is empty
								world.spawnProjectile("miab_marker_to_be_printed_block",wpos);
							end
						end
					end
]]
					-- remove scaffold
					if(args.Remove_Foreground_scaffold)then
						if (matName == "miab_scaffold") then
							if world.material(wpos, "foreground") == self.miab.ScaffoldmatName then
								blueprint.clearBlock(wpos,"foreground");
								if world.material(wpos, "foreground") ~= nil then
									Done = false
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- Objects all in one
	if not (Override_Objects) then
		if(Done) then -- objects are only placed if the blocks are done.
			for _y, _tbl in pairs(blueprint.objectTable) do
				for _x, ObjectParameter_tbl in pairs(_tbl) do
					wpos = { self.miab.pos[1] + _x, self.miab.pos[2] + _y }
					matName = ObjectParameter_tbl.Name;
					if (matName ~= nil) then
						-- place
						if(args.Place_Objects)then
							EntityIDs = (world.entityQuery(wpos,wpos,{notAnObject = true}))
							Nr_EntityIDs = 0;
							for i, EntityID in pairs(EntityIDs) do
								if (EntityID ~= entity.id()) and (entityInOurBox(EntityID)) then
									-- "player","monster","object","itemdrop","projectile","plant","plantdrop","effect","npc"
									cur_ent_Type = world.entityType(EntityID)
									if (   (cur_ent_Type == "player")
										or (cur_ent_Type == "monster")
										or (cur_ent_Type == "npc")
										--or (cur_ent_Type == "plant")
										) then
										Nr_EntityIDs = Nr_EntityIDs+1;
										self.miab.obstructionTable[EntityID] = true
									end
								end
							end
							if not (Nr_EntityIDs > 0) then
								-- world block is not equal blueprint block
								if (args.Place_Requires_Item)then
									-- check if we have that item
									if (blueprint.haveItemsInTable({matName,1},blueprint.accquiredItemsTable)) then
										-- try to place
										if(world.placeObject(matName, wpos, ObjectParameter_tbl.Facing))then
											-- was placed -> remove from stash
											blueprint.removeItemsFromTable({matName,1},blueprint.accquiredItemsTable)
											anything_could_be_printed_this_run = true;
										else
											-- coudn`t place
												-- We do not try to place again for Objects.
												-- It might be the case that they cant fit.
												-- We drop them instead at the end
												-- when the remaining inventory is spit out
											--Done = false;
										end
									else
										-- we dont have that item
									end
								else
									-- try to place
									if (world.placeObject(matName, wpos, ObjectParameter_tbl.Facing)) then
	-- TODO: implement set other object properties,
	-- like content of chests, here.
										-- was placed -> remove from stash
										blueprint.removeItemsFromTable({matName,1},blueprint.accquiredItemsTable)
										anything_could_be_printed_this_run = true;
									else
										-- coudn`t place
											-- We do not try to place again for Objects.
											-- It might be the case that they cant fit.
											-- We drop them instead at the end
											-- when the remaining inventory is spit out
										--Done = false;
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if (args.Continue_if_placement_gets_stuck) then
		if (anything_could_be_printed_this_run) then
			self.miab.was_able_to_print_something_at_some_point = true;
		end
	end

	if (Done) then
		if(args.Continue_on_sucess) then
			self.miab.buildingStage = self.miab.buildingStage + 1;
		end
	else
		if (args.Deconstruct_on_Fail) then
			self.miab.buildingStage = 255
		end
		if not (anything_could_be_printed_this_run) then
			-- we could not print now
			if(args.Continue_if_placement_gets_stuck) then
				if (self.miab.was_able_to_print_something_at_some_point) then
					-- WORKAROUND:
					-- this happens if the player jumps into the print after it started.
					-- we could already print at some point since activation.
					-- in this run Done is false. So something was not obstructed by entities and we triied to print there without success
					-- that means that the clearance check while building did not catch everything that prevents building.
					-- although in my test case it was the player which we clearly check
					-- so the players seem to not exist in some blocks but at the same time still prevents printing to those blocks.
					-- maybe its the players weapon or something ?
					-- until we can determine exactly where the player or other entities prevent printing we have to stop triing to print at some point which is here.
					self.miab.buildingStage = self.miab.buildingStage + 1;
				else
					-- we could never print since activation
					if (args.Deconstruct_on_nothing_could_be_printed) then
						self.miab.buildingStage = 256
					end
				end
			else
				if (args.Deconstruct_on_nothing_could_be_printed) then
					self.miab.buildingStage = 256
				end
			end
		end
	end
end

function entityInOurBox(entId)
	local box = { self.miab.pos[1], self.miab.pos[2], self.miab.pos[1] + blueprint.boundingBoxSize[1], self.miab.pos[2] + blueprint.boundingBoxSize[2] }
	local pos = world.entityPosition(entId)
	if (pos[1] < box[1]) then
		return false
	elseif (pos[1] > box[3]) then
		return false
	elseif (pos[2] < box[2]) then
		return false
	elseif (pos[2] > box[4]) then
		return false
	end
	return true
end

function FloatUnanchored()
	entity.playImmediateSound("/sfx/interface/clickon_error.ogg")
	if os.time() > self.miab.particleDelay then
		entity.burstParticleEmitter("unanchored")
		self.miab.particleDelay = os.time() + 3
	end
end

function FloatObstructed()
	if (debug_mode) then world.logInfo("FloatObstructed() begins") end
	local dist
	if self.miab.obstructionTable then
		entity.playImmediateSound("/sfx/interface/clickon_error.ogg")
		if os.time() > self.miab.particleDelay then
			for _id, _val in pairs(self.miab.obstructionTable) do
				dist = world.distance(world.entityPosition(_id), self.miab.pos)
				if (debug_mode) then world.logInfo(tostring(_id) .. " : " .. tostring(world.entityName(_id)) .. " @ " .. tostring(dist[1]) .. ", " .. tostring(dist[2])) end
				world.spawnProjectile("miab_obstruction", {world.entityPosition(_id)[1], world.entityPosition(_id)[2]}, entity.id(), {0, 0}, true)
			end
			entity.burstParticleEmitter("obstructed")
			self.miab.particleDelay = os.time() + 3
		end
	end
	self.miab.obstructionTable = nil
	if (debug_mode) then world.logInfo("FloatObstructed() ends") end
end