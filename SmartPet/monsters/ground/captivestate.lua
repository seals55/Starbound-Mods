captiveState = {
  closeDistance = 4,
  runDistance = 12,
  teleportDistance = 36,
}

-- SMARTPET START
function firstEmpty(table)
  for i=1,99 do
    if table[i] == nil then return i end
  end
  return 100
end

function countItems(table)
  local ret = 0
  for _ in pairs(table) do ret = ret + 1 end
  return ret
end

function compareTables(firstTable, secondTable)
  if (next(firstTable) == nil) and (next(secondTable) == nil) then 
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

function captiveState.getCapacity()
  local ret = 5
  for i=1,3 do
    if storage.discs[i] == "storedisc" then ret = ret + 15 end
  end
  return ret
end

function captiveState.teleport(pos)
  world.spawnProjectile("tpout", entity.position())
  pos = { pos[1], pos[2] + 0.25 }
  entity.setPosition(pos)
  world.spawnProjectile("tpin", pos)
  self.stuckticks = 0
  self.jumpTimer = 0
end

function captiveState.storeItem(item)
  if item == nil then return nil end
  for i,stack in pairs(storage.itemz) do
    if (stack.name == item.name) and (stack.count < 1000) and compareTables(item.data, stack.data) then
      if (stack.count + item.count > 1000) then
        local i = firstEmpty(storage.itemz)
        storage.itemz[i] = { name = item.name, count = stack.count + item.count - 1000, data = item.data }
        item.count = 1000 - stack.count - item.count
      end
      storage.itemz[i].count = stack.count + item.count
      return true
    end
  end
  local i = firstEmpty(storage.itemz)
  storage.itemz[i] = item
  return false
end
-- SMARTPET END

function captiveState.enter()
  if not isCaptive() or hasTarget() then return nil end

  -- SMARTPET START
  self.prevpos = self.position
  self.stuckticks = 0
  -- SMARTPET END

  return { running = false }
end

function captiveState.enterWith(params)
  if not isCaptive() then return nil end

  -- SMARTPET START
  self.prevpos = self.position
  self.stuckticks = 0
  -- SMARTPET END

  -- We're masquerading as wander for captive monsters
  if params.wander then
    return { running = false }
  end

  return nil
end

function captiveState.update(dt, stateData)
  -- SMARTPET START
  local capacity = captiveState.getCapacity()
  if countItems(storage.itemz) < capacity then
    if self.itemzhold > 0 then
      self.itemzhold = self.itemzhold - 1
    else
      local itemz = world.itemDropQuery(self.position, 3.25)
      if #itemz > 0 then
        for i,v in pairs(itemz) do
          local en = world.entityName(v)
          if (string.sub(en, -4) ~= "disc") and (string.sub(en, -10) ~= "capturepod") then
            captiveState.storeItem(world.takeItemDrop(v, entity.id()))
            if countItems(storage.itemz) >= capacity then break end
          end
        end
        if countItems(storage.itemz) >= capacity then
          world.spawnProjectile("petinvfull", entity.toAbsolutePosition({ 0, 2 }), entity.id(), { 0, 1 }, true)
        end
      end
    end
  end
  -- SMARTPET END
  if hasTarget() then return true end

  -- Translate owner uuid to entity id
  if self.ownerEntityId ~= nil then
    if not world.entityExists(self.ownerEntityId) then
      self.ownerEntityId = nil
    end
  end

  if self.ownerEntityId == nil then
    local playerIds = world.playerQuery(self.position, 50)
    for _, playerId in pairs(playerIds) do
      if world.entityUuid(playerId) == storage.ownerUuid then
        self.ownerEntityId = playerId
        break
      end
    end
  end

  -- Owner is nowhere around
  if self.ownerEntityId == nil then
    return false
  end

  -- SMARTPET START
  if self.petinvinit == nil then
    if countItems(storage.itemz) >= capacity then
      world.spawnProjectile("petinvfull", entity.toAbsolutePosition({ 0, 2 }), entity.id(), { 0, 1 }, true)
    end
    self.petinvinit = true
  end
  -- SMARTPET END

  local ownerPosition = world.entityPosition(self.ownerEntityId)
  local toOwner = world.distance(ownerPosition, self.position)
  local distance = math.abs(toOwner[1])

  local movement = toOwner[1]
  -- SMARTPET START
  if (distance > captiveState.teleportDistance) or (math.abs(toOwner[2]) > captiveState.teleportDistance) then
    movement = 0
    captiveState.teleport(ownerPosition)
  elseif (distance < captiveState.closeDistance) and (toOwner[2] > -captiveState.closeDistance) then
    stateData.running = false
    movement = 0
  end
  -- SMARTPET END

  if (distance > captiveState.runDistance) or not entity.onGround() then
    stateData.running = true
  end

  entity.setAnimationState("attack", "idle")
  move({ movement, toOwner[2] }, captiveState.closeDistance)
  entity.setRunning(stateData.running)

  -- SMARTPET START
  local pos = entity.position()
  if movement ~= 0 then
    if math.abs(pos[1] - self.prevpos[1]) < 1 then
      self.stuckticks = self.stuckticks + 1
    else
      self.prevpos = self.position
      self.stuckticks = 0
    end
  end

  if toOwner[2] > captiveState.runDistance then
    self.stuckticks = self.stuckticks + 1
  end

  if self.stuckticks > 40 then
    captiveState.teleport(ownerPosition)
  end
  -- SMARTPET END

  return false
end
