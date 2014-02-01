
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 200
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("quadruped", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 3 })
	world.spawnMonster("quadruped", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 3 })
	world.spawnMonster("quadruped", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 3 })
	world.spawnMonster("crewquadrupedminiboss2", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 3 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Good luck fighting!" } }
end