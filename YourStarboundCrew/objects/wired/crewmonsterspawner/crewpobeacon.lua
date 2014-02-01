
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 3000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("po", entity.toAbsolutePosition({ 20.0, 3.0 }), { level = 5 })
	world.spawnMonster("po", entity.toAbsolutePosition({ -20.0, 3.0 }), { level = 5 })
	world.spawnMonster("pogolem", entity.toAbsolutePosition({ -22.0, 3.0 }), { level = 5 })
	world.spawnMonster("toxicgolem", entity.toAbsolutePosition({ 22.0, 3.0 }), { level = 5 })
	world.spawnMonster("megapo", entity.toAbsolutePosition({ 28.0, 3.0 }), { level = 5 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 30.0 }), amount)
	return { "ShowPopup", { message = "Have fun opening chests!" } }
end