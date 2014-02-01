
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 2000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("aviansentry", entity.toAbsolutePosition({ 20.0, 3.0 }), { level = 4 })
	world.spawnMonster("aviansentry", entity.toAbsolutePosition({ -20.0, 3.0 }), { level = 4 })
	world.spawnMonster("smallflying", entity.toAbsolutePosition({ -21.0, 10.0 }), { level = 4 })
	world.spawnMonster("smallflying", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 4 })
	world.spawnMonster("smallflyingminiboss", entity.toAbsolutePosition({ 0.0, 30.0 }), { level = 4 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 30.0 }), amount)
	return { "ShowPopup", { message = "Have fun shooting birdies!" } }
end