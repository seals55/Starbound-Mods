
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 4000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("tentaclecomet", entity.toAbsolutePosition({ 20.0, 13.0 }), { level = 7 })
	world.spawnMonster("tentaclecomet", entity.toAbsolutePosition({ -20.0, 13.0 }), { level = 7 })
	world.spawnMonster("tentaclecometspore", entity.toAbsolutePosition({ -22.0, 3.0 }), { level = 7 })
	world.spawnMonster("tentaclecometspore", entity.toAbsolutePosition({ 22.0, 3.0 }), { level = 7 })
	world.spawnMonster("tentaclecometspore", entity.toAbsolutePosition({ -12.0, 3.0 }), { level = 7 })
	world.spawnMonster("tentaclecometspore", entity.toAbsolutePosition({ 12.0, 3.0 }), { level = 7 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 30.0 }), amount)
	return { "ShowPopup", { message = "Avenge Earth!" } }
end