
function init(args)
	entity.setInteractive(true)
end

function onInteraction(args)

  local reward = "money"
  local amount = 1000
  
  entity.smash()
  
  entity.setAnimationState("beaconState", "active")
    world.spawnMonster("bonebird", entity.toAbsolutePosition({ 20.0, 10.0 }), { level = 8 })
	world.spawnMonster("smallflying", entity.toAbsolutePosition({ 21.0, 10.0 }), { level = 8 })
	world.spawnMonster("smallflying", entity.toAbsolutePosition({ 22.0, 10.0 }), { level = 8 })
	world.spawnMonster("smallflyingminiboss4", entity.toAbsolutePosition({ 23.0, 10.0 }), { level = 7 })
	world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
	return { "ShowPopup", { message = "Have fun shooting aliens!" } }
end