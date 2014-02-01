
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "alienmeat"
  local amount = 5
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("crewhuntingquadruped", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 1 })
	world.spawnMonster("crewhuntingquadruped", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 1 })
	world.spawnMonster("crewhuntingquadruped", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 1 })
	world.spawnMonster("crewhuntingquadruped", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 1 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Have fun hunting!" } }
end