
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 1000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("glitchknight", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 3 })
	world.spawnMonster("glitchknight", entity.toAbsolutePosition({ -21.0, 10.0 }), { level = 3 })
	world.spawnMonster("glitchspider", entity.toAbsolutePosition({ 10.0, 10.0 }), { level = 3 })
	world.spawnMonster("glitchspider", entity.toAbsolutePosition({ -10.0, 10.0 }), { level = 3 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 20.0 }), amount)
	return { "ShowPopup", { message = "Have fun shooting Glitch!" } }
end