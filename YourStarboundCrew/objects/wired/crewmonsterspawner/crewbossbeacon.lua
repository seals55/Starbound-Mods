
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 3000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("penguinUfo", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 2 })
	world.spawnMonster("dragonboss", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 4 })
	world.spawnMonster("jellyboss", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 5 })
	world.spawnMonster("robotboss", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 3 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Good luck!" } }
end