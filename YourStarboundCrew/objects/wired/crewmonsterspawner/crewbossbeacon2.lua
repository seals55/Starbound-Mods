
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 30000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("penguinUfo", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 8 })
	world.spawnMonster("dragonboss", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 8 })
	world.spawnMonster("jellyboss", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 8 })
	world.spawnMonster("robotboss", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 8 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Are you sure...?" } }
end