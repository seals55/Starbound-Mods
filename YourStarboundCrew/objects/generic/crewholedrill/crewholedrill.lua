function init(args)
  self.state = stateMachine.create({
    "deadState",
    "drillingState",
    "returnState"
  })
  entity.setInteractive(true)
  
  self.drilling = false
  self.returning = false
  
  if storage.items == nil then storage.items = {} end
  
  entity.scaleGroup("rope", {1, 4})
  entity.rotateGroup("rope", math.pi)
  entity.rotateGroup("flag", -math.pi / 2)
  
  checkNode()
  entity.setAllOutboundNodes(false)
  
  if entity.direction() < 0 then
    entity.setAnimationState("flipped", "left")
  end
end

--------------------------------------------------------------------------------

function onNodeConnectionChange(args)

end

function onInboundNodeChange(args)
  checkNode()
end

function checkNode()
  if entity.isInboundNodeConnected(0) then
    if entity.getInboundNodeLevel(0) and self.returning == false and #storage.items == 0 then
      self.drilling = true
    else
      self.drilling = false
    end
  end
end

function onInteraction(args)
  if entity.isInboundNodeConnected(0) == false and self.returning == false and #storage.items == 0 then
    self.drilling = true
  elseif #storage.items > 0 and self.drilling == false and self.returning == false then
    dropItems()
  end
end

--------------------------------------------------------------------------------
function main(args)
  self.state.update(entity.dt())
end

--------------------------------------------------------------------------------

function tableEmpty(checkTable)
  for i,value in pairs(checkTable) do
    return false
  end
  return true
end

function compareTables(firstTable, secondTable)
  if tableEmpty(firstTable) and tableEmpty(secondTable) then 
    return true
  end
  for key,value in pairs(firstTable) do
    if firstTable[key] ~= secondTable[key] then 
      return false 
    end
  end
  for key,value in pairs(secondTable) do
    if firstTable[key] ~= secondTable[key] then 
      return false 
    end
  end
  return true
end

--------------------------------------------------------------------------------

function storeItem(itemDescription)
  for i,stack in ipairs(storage.items) do
    if stack.name == itemDescription.name and compareTables(itemDescription.data, stack.data) then
      stack.count = stack.count + itemDescription.count
      return true
    end
  end
  storage.items[#storage.items+1] = itemDescription
  return false
end

function dropItems()
  local itemDropOffset = entity.configParameter("itemDropOffset")
  local position = entity.position()
  local outputPosition = {position[1] + itemDropOffset[1], position[2] + itemDropOffset[2]}
  for i,stack in ipairs(storage.items) do
    if stack then
      if next(stack.data) ~= nil then
        world.spawnItem(stack.name, outputPosition, stack.count, stack.data)
      else
        world.spawnItem(stack.name, outputPosition, stack.count)
      end
    end
  end
  storage.items = {}
end

--------------------------------------------------------------------------------

deadState = {}

function deadState.enter()
  return {}
end

function deadState.enteringState(stateData)
  if entity.direction() < 0 then
    entity.setAnimationState("flipped", "left")
  else
    entity.setAnimationState("flipped", "right")
  end
  self.returning = false
end

function deadState.update(dt, stateData)

  if #storage.items == 0 then
    entity.rotateGroup("flag", -math.pi / 2)
  else
    entity.rotateGroup("flag", 0)
  end
  
  if self.drilling == false then
    return false
  end
  
  return true
end

function deadState.leavingState(stateData)
  self.state.pickState({drilling = self.drilling})
end
--------------------------------------------------------------------------------

drillingState = {}

function drillingState.enterWith(stateData)
  if stateData.drilling ~= nil and stateData.drilling then
    return {drilling = true, timer = 0, currentDepth = 0, reDig = true, first = true, jammed = false}
  end
end

function drillingState.enteringState(stateData)
  self.drilling = true
  entity.setAnimationState("flipped", "invisible")
  entity.setAllOutboundNodes(true)
end

function drillingState.drillPosition(currentDepth)
  local drillingDrillOffset = entity.configParameter("drillingDrillOffset")
  local position = entity.position()
  local drillPosition = {position[1] + drillingDrillOffset[1], position[2] + drillingDrillOffset[2] - currentDepth}
  return drillPosition
end

function drillingState.digLayer(stateData, spawnProjectile)
  local position = entity.position()
  local digSpeed = entity.configParameter("digSpeed")
  local drillingDrillOffset = entity.configParameter("drillingDrillOffset")
  local drillSpeed = entity.configParameter("drillProjectileSpeed")
  local drillProjectile = entity.configParameter("drillProjectile")
  
  local startPos = {position[1] + 1.5, position[2] + 0.5 - stateData.currentDepth}
  local endPos = {position[1] + 2.5, position[2] + 0.5 - stateData.currentDepth}
  local tiles = world.collisionBlocksAlongLine(startPos, endPos, true, 2)
  
  local damageSource = {entity.position()[1] + 2, entity.position()[2] + 1 - stateData.currentDepth}
  world.damageTiles(tiles, "foreground", damageSource, "blockish", 2000)

  if spawnProjectile then
    world.spawnProjectile(drillProjectile, drillingState.drillPosition(stateData.currentDepth), entity.id(), {0, -1}, false, {speed = drillSpeed})
  end
  
  local tiles = world.collisionBlocksAlongLine(startPos, endPos, true, 2)
  if #tiles > 0 then
    return true
  end
  
  return false
end

function drillingState.pickupItemDrops(drillPosition)
  local pickupRange = entity.configParameter("pickupRange")
  local nearbyDroppedItems = world.itemDropQuery(drillPosition, pickupRange)

  for i, entityId in ipairs(nearbyDroppedItems) do
    if world.entityExists(entityId) then
      local itemDescription = world.takeItemDrop(entityId)
      if itemDescription then
        storeItem(itemDescription)
      end
    end
  end
end

function drillingState.update(dt, stateData)
  local digDepth = entity.configParameter("digDepth")
  local digSpeed = entity.configParameter("digSpeed")
  local drillingDrillOffset = entity.configParameter("drillingDrillOffset")
  
  --This is in case there's grass or sand or whatever
  if stateData.reDig or stateData.first then
    stateData.reDig = drillingState.digLayer(stateData, stateData.first)
    stateData.first = false
  end
  
  if stateData.currentDepth < digDepth then
    if stateData.timer >= digSpeed then
       
      if drillingState.digLayer(stateData, false) or self.drilling == false then
        stateData.jammed = true
        return true
      end
      
      stateData.timer = 0
      stateData.currentDepth = stateData.currentDepth + 1
      
      stateData.reDig = drillingState.digLayer(stateData, stateData.currentDepth < digDepth)
      
      drillingState.pickupItemDrops(drillingState.drillPosition(stateData.currentDepth))
    end
    stateData.timer = stateData.timer + dt
    
    local ropeScale = 8 + 8 * stateData.currentDepth + 8 * (stateData.timer / digSpeed)
    entity.scaleGroup("rope", {1, ropeScale})
    
    return false
  end
  
  return true
end

function drillingState.leavingState(stateData)
  drillingState.pickupItemDrops(drillingState.drillPosition(stateData.currentDepth))
  entity.setAllOutboundNodes(false)
  
  self.state.pickState({currentDepth = stateData.currentDepth, jammed = stateData.jammed})
end
--------------------------------------------------------------------------------

returnState = {}

function returnState.enterWith(stateData)
  if stateData.currentDepth ~= nil then
    local digSpeed = entity.configParameter("digSpeed")
    return {currentDepth = stateData.currentDepth, timer = -digSpeed, first = true, jammed = stateData.jammed}
  end
end

function returnState.drillPosition(currentDepth, jammed)
  local position = entity.position()
  local drillOffset = entity.configParameter("returningDrillOffset")
  if jammed then drillOffset = entity.configParameter("jammedDrillOffset") end
  local drillPosition = {position[1] + drillOffset[1], position[2] + drillOffset[2] - currentDepth}
  return drillPosition
end

function returnState.enteringState(stateData)
  self.drilling = false
  self.returning = true
  local drillProjectile = entity.configParameter("drillProjectile")
  
  world.spawnProjectile(drillProjectile, returnState.drillPosition(stateData.currentDepth, stateData.jammed), entity.id(), {0, -1}, false, {speed = 0.01})
  if stateData.jammed then stateData.jammed = false end
end

function returnState.update(dt, stateData)
  local digSpeed = entity.configParameter("returnSpeed")
  local drillSpeed = entity.configParameter("returnProjectileSpeed")
  local position = entity.position()
  local returnProjectile = entity.configParameter("returnProjectile")
  
  if stateData.timer >= 0 and stateData.first then
    world.spawnProjectile(returnProjectile, returnState.drillPosition(stateData.currentDepth, stateData.jammed), entity.id(), {0, 1}, false, {speed = drillSpeed})
    stateData.first = false
  end
  
  if stateData.currentDepth >= 0 then
    if stateData.timer >= digSpeed then
      stateData.timer = 0
      stateData.currentDepth = stateData.currentDepth - 1
      
      if stateData.currentDepth > 0 then
        world.spawnProjectile(returnProjectile, returnState.drillPosition(stateData.currentDepth, stateData.jammed), entity.id(), {0, 1}, false, {speed = drillSpeed})
      end
    end
    stateData.timer = stateData.timer + dt
    
    local ropeScale = 16 + 8 * stateData.currentDepth - 8 * (math.max(stateData.timer, 0) / digSpeed), 0 --16 here instead of 4 because the projectile is 1 block lower, and also add 4 some to remove the gap
    entity.scaleGroup("rope", {1, ropeScale})
    
    return false
  end
  
  return true
end

function returnState.leavingState(stateData)
  self.state.pickState()
end