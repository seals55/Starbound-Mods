
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 100
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("bonebird", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 2 })
	world.spawnMonster("smallflying", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 2 })
	world.spawnMonster("smallflying", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 2 })
	world.spawnMonster("smallflyingminiboss", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 2 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Have fun shooting aliens!" } }
end