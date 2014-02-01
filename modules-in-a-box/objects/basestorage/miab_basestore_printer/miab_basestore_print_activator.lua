function init(virtual)
	if not virtual then
		entity.setInteractive(true);
		
			-- Options for read process
		local Writer_options = {};
		local offset                               = entity.configParameter("miab_printer_offset", {0.0, 0.0})
		Writer_options.Writer_Position             = entity.toAbsolutePosition(offset)
		Writer_options.Spawn_Unplaceables_Position = entity.toAbsolutePosition({ 0, 4 })
		Print_Init(Writer_options);
		
		Done_printing = false; -- flag to end polling
	end
end

function onInteraction(args)
--	blueprint.logDump()
	Print_Start();
end

function main()

	if not(Done_printing) then
		-- needs to be polled
		Done_printing = Print_Module();
	else
		entity.smash()
	end
	
end

function die()
	if Done_printing == false then
		world.spawnItem("miab_basestore_printer", entity.position(), 1, blueprint.toConfigTable())
		entity.smash()
	end
end