
function init(args)
  entity.setInteractive(false)
  entity.setAnimationState("switchState", "on")
end

function main()
  if world.isVisibleToPlayer(entity.boundBox()) then
    return nil
  end
  
  local reward = "money"
  local amount = 500
  
  local npcSpecies = entity.randomizeParameter("spawner.npcSpeciesOptions")
  local npcType = entity.randomizeParameter("spawner.npcTypeOptions")
  local npcParameter = entity.randomizeParameter("spawner.npcParameterOptions")
  npcParameter.scriptConfig = { spawnedBy = entity.position() }
  world.spawnNpc(entity.toAbsolutePosition({ 0.0, 2.0 }), npcSpecies, npcType, entity.level(), 0, npcParameter);
  world.spawnItem(reward, entity.toAbsolutePosition({ 0.0, 3.0 }), amount)
  entity.smash()
  return { "ShowPopup", { message = "The U.S.C.M wishes you luck in apprehending the criminal." } }
end