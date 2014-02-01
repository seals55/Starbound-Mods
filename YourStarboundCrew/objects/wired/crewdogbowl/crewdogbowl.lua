
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

    world.spawnMonster("pinfriend", entity.toAbsolutePosition({ 2.0, 0.0 }), { level = 2 })
	return { "ShowPopup", { message = "Woof!" } }
end