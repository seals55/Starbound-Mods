
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 300
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("quadruped", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 4 })
	world.spawnMonster("quadruped", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 4 })
	world.spawnMonster("quadruped", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 4 })
	world.spawnMonster("crewquadrupedminiboss3", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 4 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Good luck fighting!" } }
end