
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 2500
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("chesttrapper", entity.toAbsolutePosition({ 20.0, 3.0 }), { level = 2 })
	world.spawnMonster("giftmonster", entity.toAbsolutePosition({ -20.0, 3.0 }), { level = 3 })
	world.spawnMonster("chesttrapper", entity.toAbsolutePosition({ -22.0, 3.0 }), { level = 4 })
	world.spawnMonster("chesttrapper", entity.toAbsolutePosition({ 22.0, 3.0 }), { level = 5 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 30.0 }), amount)
	return { "ShowPopup", { message = "Have fun opening chests!" } }
end