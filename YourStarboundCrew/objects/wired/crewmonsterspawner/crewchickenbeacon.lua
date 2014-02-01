
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 3000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("chicken", entity.toAbsolutePosition({ 20.0, 3.0 }), { level = 6 })
	world.spawnMonster("chicken", entity.toAbsolutePosition({ -20.0, 3.0 }), { level = 6 })
	world.spawnMonster("robotchicken", entity.toAbsolutePosition({ -22.0, 3.0 }), { level = 6 })
	world.spawnMonster("robotchicken", entity.toAbsolutePosition({ 22.0, 3.0 }), { level = 6 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 30.0 }), amount)
	return { "ShowPopup", { message = "Bawk bawk!" } }
end