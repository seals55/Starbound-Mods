function init(args)
	entity.setInteractive(true)

	-- state machine
	Done_reading = false;
	Reading_Started = false;

	-- wiring
	entity.setAllOutboundNodes(false)
	onNodeConnectionChange()
	self.corners = {}
	
	-- Animation
	self.Animation_Color = {};
	set_green_animation()
end

function onInteraction(args)
	if (entity.isInboundNodeConnected(0)) then
		return
	end

	onActivation()
end

-- old onInteraction() is now onActivation() and is called when interacted with (if unwired) or when receiving a signal from wire
function onActivation(args)
	if not(Is_In_Post_Hoover_Stage()) then
		-- Interaction starts the process
		
		-- Options for read process
		local Reader_options = {};
		Reader_options.Reader_Position              = entity.toAbsolutePosition({ 0.0, 0.0 })
		Reader_options.Spawn_Printer_Item_Position  = entity.toAbsolutePosition({ 0, 4 })
		Reader_options.Spawn_Undigestables_Position = entity.toAbsolutePosition({ 0, 4 })
		Reader_options.AreaToScan                   = define_area_to_scan();
		Reader_options.useInventory                 = entity.configParameter("miab_useInventory", true);
		Reader_options.Plot_Object_JSON             = false;
		Reader_options.Plot_Recipe_JSON             = false;
		Reader_options.Length_of_BP_Animation_in_s  = 3
		
		if(Reader_options.AreaToScan ~= nil) then
			-- start reading process
			Read_Start(Reader_options);
			Done_reading = false;
		end
	else
		-- Interactions while in post hoover stage stop the post hoover stage
		-- in that stage the reader will hoover up anything
		-- that is thrown at it until it did hoover up all
		-- required items to build the blueprint.
		-- sometimes that might not be possible, so here you can stop it.
		-- The blueprint will then be created without the
		-- missing parts. The missing parts will not be printed later on.
		End_Post_Hoover_Stage();
	end
end

function main()
	-- this needs to be polled until done
	if not(Done_reading) then
		Read_Module();
	end
end

function define_area_to_scan()
-- TODO: read this from scanner object file. its already implicitly defined by frame size and pixel offset
	-- SSS
	-- SSR <-- R is the root, S is blocks occupied by the scanner
	-- due to the layout of the box (inside of the corners in X direction) the Y coordintae of this doesnt need to be handled
--	local size_of_scanner = {3,2} -- the total occupied blocks of the scanner
--	local origin_of_scanner = {3,1} -- the point where the scanner is anchored
	local size_of_scanner = entity.configParameter("miab_scannerSize", {3.0, 2.0})
	local origin_of_scanner = entity.configParameter("miab_scannerOrigin", {3.0, 1.0})

	local bounds  = {0, 0, 0, 0}
	-- defualt corners are the corners of the scanner itself
	local pos_1      = entity.position()
	local pos_2      = entity.position()
	local ents    = entity.getOutboundNodeIds(0)
	local use_scanner_as_corner = true

	-- handle different ammounts of receivers and wired or not
	local corners = countConnectedCorners()
	if corners == 0 then
		return nil
	elseif corners == 1 then
		-- use one corner and the scanner itself
		pos_2 = world.entityPosition(self.corners[1])
	else
		-- use two corners
		pos_1 = world.entityPosition(self.corners[1])
		pos_2 = world.entityPosition(self.corners[2])
		use_scanner_as_corner = false
	end
	
	-- find smallest X Corner coordinate of the two corners
	-- and use that for the left of the bounding box
	-- use the bigger one for right side
	-- using world.distance()
	local dist = world.distance(pos_2, pos_1)
	local xMax = dist[1]
	local yMax = dist[2]
	if xMax > 1 then
		bounds[1] = pos_1[1] -- left
		bounds[3] = pos_2[1] -- right
		scanner_X_corner = "left" -- if one of the corners is the scanner it is the left one
	elseif xMax < 1 then
		bounds[1] = pos_2[1] -- left
		bounds[3] = pos_1[1] -- right
		scanner_X_corner = "right" -- if one of the corners is the scanner it is the right one
	else
		return nil
	end
	
	-- find smallest Y Corner coordinate of the two corners
	-- and use that for the bottom of the bounding box
	-- use the bigger one for top side
	if (pos_1[2] < pos_2[2]) then
		bounds[2] = pos_1[2] -- down
		bounds[4] = pos_2[2] -- up
	elseif (pos_1[2] > pos_2[2]) then
		bounds[2] = pos_2[2] -- down
		bounds[4] = pos_1[2] -- up
	else
		return nil
	end
	
	if (use_scanner_as_corner) then
--local size_of_scanner = {3,2} -- the total occupied blocks of the scanner
--local origin_of_scanner = {3,1} -- the point where the scanner is anchored
		-- we have to shift a bit accoring to the size of the scanner
		-- X coordinate shift due to scanner size
		if (scanner_X_corner == "left") then
			-- if the scanner is left corner
			bounds[1] = bounds[1] + (size_of_scanner[1]-origin_of_scanner[1])
		elseif (scanner_X_corner == "right") then
			-- if the scanner is right corner
			bounds[3] = bounds[3] + (size_of_scanner[1]-origin_of_scanner[1]) - size_of_scanner[1] +1
		else
			return nil
		end
		-- Y coordinate is not of interest. we allways use the origin of the scanner.
		-- not adapting Y will never leed to the scanner beeing eaten by itself
	end

	-- so far we are directly ON the corners.
	-- we sorted out which one is bottom left and which one is top right
	-- we also shifted one of the corners if it was the scanner itself accoring to the size of the scanner in order not to eat the scanner itself

	-- we now apply an offset for the box.
	-- we dont want to scan AT the corners, but inside of the corners (in X direction "inside")
	-- Offsets for scanning objects:
	-- 1 block right, 0 blocks up for bottom left
	-- 1 block left, 0 blocks down for top right
	bounds[1] = bounds[1] + 1.0 --( <- offset from bottom left
	bounds[2] = bounds[2] + 0.0 --(
	bounds[3] = bounds[3] - 1.0 --( <- offset from top right corner_2
	bounds[4] = bounds[4] - 0.0 --(

	-- although this is already checked we check again if the box has a zero or negativ area
	-- "negative" meaing that what is left and right (or up and down) might be labled wrong
	dist = world.distance({bounds[3], bounds[4]}, {bounds[1], bounds[2]})
	xMax = dist[1]
	yMax = dist[2]
	if xMax < 1 or yMax < 1 then
		return nil
	end
	return bounds
end

----- Wiring -----
-- returns the number of scanning corners connected to our outbound node
function countConnectedCorners()
	local count = 0
	for i,nodes_j in pairs(entity.getOutboundNodeIds(0)) do
		for i_nodes,node_ID in pairs(nodes_j) do
			if (i_nodes == 1) then
				if world.entityName(node_ID) == "miab_basestore_receiver" then
					count = count + 1
					self.corners[count] = node_ID
				end
			end
		end
	end

	return count
end

function onNodeConnectionChange(args)
	entity.setInteractive(not entity.isInboundNodeConnected(0))
	if entity.isInboundNodeConnected(0) then
		onInboundNodeChange({ level = entity.getInboundNodeLevel(0) })
	end
end

function onInboundNodeChange(args)
	if (args.level) and (not self.level) then
		onActivation()
	end
	self.level = args.level
end

----- Animation -----
function set_green_animation ()
	if (self.Animation_Color ~= "green") then
		entity.setAnimationState("DisplayState", "Green_State")
		self.Animation_Color = "green"
	end
end

function set_yellow_animation ()
	if (self.Animation_Color ~= "yellow") then
		entity.setAnimationState("DisplayState", "Yellow_State")
		self.Animation_Color = "yellow"
	end
end

function set_red_animation ()
	if (self.Animation_Color ~= "red") then
		entity.setAnimationState("DisplayState", "Red_State")
		self.Animation_Color = "red"
	end
end

function set_blueprint_animation ()
	if (self.Animation_Color ~= "blueprint") then	
		entity.setAnimationState("DisplayState", "Blueprint_State")
		self.Animation_Color = "blueprint"
	end
end