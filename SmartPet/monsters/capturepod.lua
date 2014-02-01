-- Helper functions for entities that can be captured by a capturepod
capturepod = {}

-- SMARTPET START
function stringends(str, en)
  return string.sub(str, -string.len(en)) == en
end

function distSq(v1, v2)
  local x = v2[1] - v1[1]
  local y = v2[2] - v1[2]
  return x * x + y * y
end

function sumVec(v)
  return entity.toAbsolutePosition({ v[1] * entity.facingDirection(), v[2] })
end

function isMelee(kind)
  local valid = { "1hsword", "2hsword", "axe", "dagger", "direct", "fryingpan", "hammer", "slash", "spear" }
  for k,v in pairs(valid) do
    if v == kind then return true end
  end
  return false
end

function capturepod.isFriendly()
  for i=1,3 do
    if storage.discs[i] == "calmdisc" then return true end
  end
  return false
end

function capturepod.moveHook(delta, jumpThresholdX)
  self.lastdelta = delta
  if capturepod.oldMove ~= nil then return capturepod.oldMove(delta, jumpThresholdX) end
end

function capturepod.setTargetHook(target)
  if not capturepod.isFriendly() then
    if capturepod.oldSetTarget ~= nil then return capturepod.oldSetTarget(target) end
  end
end

function capturepod.shouldDieHook()
  if self.gotCaptured <= 0 and capturepod.isFriendly() then return false
  elseif capturepod.oldShouldDie ~= nil then return capturepod.oldShouldDie() end
end

function capturepod.mainHook()
  if capturepod.isCaptive() then
    if self.itemzhold < 1 then
      local itemz = world.itemDropQuery(self.position, 3.5)
      if #itemz > 0 then
        for i,v in pairs(itemz) do
          local name = world.entityName(v)
          if stringends(name, "disc") then
            if world.takeItemDrop(v, entity.id()) ~= nil then
              if storage.discs[3] ~= nil then world.spawnItem(storage.discs[3], sumVec({ 0, 2 })) end
              if storage.discs[2] ~= nil then storage.discs[3] = storage.discs[2] end
              if storage.discs[1] ~= nil then storage.discs[2] = storage.discs[1] end
              storage.discs[1] = name
              self.itemzhold = 33
            end
          end
        end
      end
    end
    self.lastdelta = { 0, 0 }
  end
  if capturepod.oldMain ~= nil then capturepod.oldMain() end
  if capturepod.isCaptive() then
    local dt = entity.dt()
    for i=1,3 do
      if storage.discs[i] == nil then
        self.petlight[i] = 666
        self.pethp[i] = 666
      elseif storage.discs[i] == "calmdisc" then
        self.target = 0
      elseif storage.discs[i] == "regendisc" then
        if entity.health() < entity.maxHealth() then
          entity.heal(entity.id(), entity.maxHealth() * dt / 20)
          self.pethp[i] = self.pethp[i] + dt
          if self.pethp[i] > 1.5 then
            self.pethp[i] = 0
            world.spawnProjectile("hpgas1hp", sumVec({ 0, -0.5 }))
          end
        end
      elseif storage.discs[i] == "speeddisc" then
        local v = entity.velocity()
        v[1] = v[1] + self.lastdelta[1] / 3
        entity.setVelocity(v)
      elseif storage.discs[i] == "jumpdisc" then
        local v = entity.velocity()
        if self.lastdelta[2] > 0 then
          v[2] = v[2] + self.lastdelta[2] / 3
          entity.setVelocity(v)
        end
      elseif storage.discs[i] == "lightdisc" then
        self.petlight[i] = self.petlight[i] + dt
        if self.petlight[i] >= 5 then
          self.petlight[i] = 0
          world.spawnProjectile("petlight" .. i, sumVec({ 0, -0.5 }))
        end
      end
    end
  end
end
-- SMARTPET END

--------------------------------------------------------------------------------
function capturepod.onInit()
  -- SMARTPET START
  if storage.itemz == nil then
    storage.itemz = entity.configParameter("itemz", {})
  end
  if storage.discs == nil then
    storage.discs = entity.configParameter("discs", {})
  end
  if self.itemzhold == nil then
    self.itemzhold = 0
  end
  self.gotCaptured = 0
  self.petlight = { 666, 666, 666 }
  self.pethp = { 666, 666, 666 }
  self.friendly = false
  if capturepod.oldMain == nil then
    capturepod.oldMain = main
    main = capturepod.mainHook
  end
  if capturepod.oldMove == nil then
    capturepod.oldMove = move
    move = capturepod.moveHook
  end
  if capturepod.oldSetTarget == nil then
    capturepod.oldSetTarget = setTarget
    setTarget = capturepod.setTargetHook
  end
  if capturepod.oldShouldDie == nil then
    capturepod.oldShouldDie = shouldDie
    shouldDie = capturepod.shouldDieHook
  end
  -- SMARTPET END
  if storage.ownerUuid == nil then
    local ownerUuid = entity.configParameter("ownerUuid", nil)
    if ownerUuid ~= nil then
      storage.ownerUuid = ownerUuid
    end
  end

  if storage.killCount == nil then
    local killCount = entity.configParameter("killCount", nil)
    if killCount ~= nil then
      storage.killCount = killCount
    end
  end
end

--------------------------------------------------------------------------------
function capturepod.onMonsterKilled()
  if capturepod.isCaptive() then
    if storage.killCount == nil then storage.killCount = 0 end
    storage.killCount = storage.killCount + 1

    if storage.killCount > entity.configParameter("killsPerLevel", 10) then
      local levelUpParticles = entity.configParameter("levelUpParticles", nil)
      if levelUpParticles ~= nil then
        entity.setDeathParticleBurst(levelUpParticles)
      end

      storage.killCount = 0
      self.levelUp = true
      self.dead = true
    end
  end
end

--------------------------------------------------------------------------------
function capturepod.onDamage(args)
  -- SMARTPET START
  if args.sourceKind == "harmless" then return true end
  if (args.sourceKind ~= "capture") and (args.sourceKind ~= "recapture") and (args.sourceKind ~= "reobtain") and (args.sourceKind ~= "reheal") and (args.sourceKind ~= "reset") then
    if capturepod.isCaptive() then
      if args.damage > 0 then
        for i=1,3 do
          if storage.discs[i] == "healdisc" then
            entity.heal(entity.id(), args.damage * 0.15)
            world.spawnProjectile("hpgas1hp", sumVec({ 0, -0.5 }))
          elseif (storage.discs[i] == "thorndisc") and isMelee(args.sourceKind) then
            world.spawnProjectile("petthorns", world.entityPosition(args.sourceId), entity.id(), { 0, 0 }, false, { power = args.damage / 5 })
          end
        end
      end
      if capturepod.isFriendly() then entity.heal(entity.id(), entity.maxHealth())
      else
        local hp = entity.health() / entity.maxHealth()
        for i=1,9 do
          local e = ""
          if (i - 0.5) / 9 > hp then e = "e" end
          world.spawnProjectile("hpbar" .. e, sumVec({ (i - 5) / 3, 2 }), entity.id(), { 0, 0 }, true)
        end
      end
      return (world.entityUuid(args.sourceId) == storage.ownerUuid) or self.friendly
    end
    return false
  end
  self.gotCaptured = 0
  if capturepod.isCaptive() then
    if world.entityUuid(args.sourceId) == storage.ownerUuid then
      if args.sourceKind == "reobtain" then
        for i,v in pairs(storage.itemz) do
          if next(v.data) == nil then
            world.spawnItem(v.name, sumVec({ 0, 2.5 }), v.count)
          else
            world.spawnItem(v.name, sumVec({ 0, 2.5 }), v.count, v.data)
          end
          storage.itemz[i] = nil
        end
        self.itemzhold = 33
      elseif args.sourceKind == "reset" then
        for i=1,3 do
          if storage.discs[i] ~= nil then
            world.spawnItem(storage.discs[i], sumVec({ 0, 2 }))
            storage.discs[i] = nil
          end
        end
        self.itemzhold = 33
      elseif args.sourceKind == "reheal" then
        entity.heal(entity.id(), 6666)
        world.spawnProjectile("hpgas1hp", sumVec({ 0, -0.5 }))
      else self.gotCaptured = 1 end
    end
  elseif args.sourceKind == "capture" then
    local captureHealthFraction = entity.configParameter("captureHealthFraction", nil)
    if captureHealthFraction ~= nil then
      if entity.health() / entity.maxHealth() <= captureHealthFraction then
        storage.ownerUuid = world.entityUuid(args.sourceId)
        self.gotCaptured = 4
      end
    end
  else return false
  end
  -- SMARTPET END
  if self.gotCaptured > 0 then
    local captureParticles = entity.configParameter("captureParticles", nil)
    if captureParticles ~= nil then
      entity.setDeathParticleBurst(captureParticles)
    end
    self.dead = true
  end

  return (self.gotCaptured > 0) or (world.entityUuid(args.sourceId) == storage.ownerUuid)
end

--------------------------------------------------------------------------------
function capturepod.onDie()
  if not capturepod.isCaptive() then return false end

  local parameters = entity.uniqueParameters()
  parameters.aggressive = true
  parameters.persistent = true

  parameters.damageTeamType = "friendly"
  parameters.damageTeam = 0

  parameters.ownerUuid = storage.ownerUuid
  parameters.killCount = storage.killCount

  parameters.seed = entity.seed()
  parameters.level = entity.level()
  parameters.familyIndex = entity.familyIndex()

  -- SMARTPET START
  if self.gotCaptured > 1 then parameters.level = parameters.level + self.gotCaptured - 1 end
  parameters.itemz = storage.itemz
  parameters.discs = storage.discs
  -- SMARTPET END

  if self.levelUp then
    parameters.level = parameters.level + 1
    world.spawnMonster(entity.type(), entity.position(), parameters)
  else
    -- SMARTPET START
    if self.gotCaptured > 0 then
      world.spawnItem("filledcapturepod", sumVec({ 0, 3.5 }), 1, {
        projectileConfig = {
          speed = 70,
          level = 7,
          actionOnReap = {
            {
              action = "spawnmonster",
              offset = { 0, 2 },
              type = entity.type(),
              arguments = parameters
            }
          }
        }
      })
    else
      local iid = world.spawnItem("faintedcapturepod", sumVec({ 0, 3.5 }), 1, {
        memory = {
          {
            action = "spawnmonster",
            offset = { 0, 2 },
            type = entity.type(),
            arguments = parameters
          }
        }
      })
      if (self.ownerEntityId ~= nil) and world.entityExists(self.ownerEntityId) then
        world.takeItemDrop(iid, self.ownerEntityId)
        world.spawnItem("faintedcapturepod", world.entityPosition(self.ownerEntityId), 1, {
          memory = {
            {
              action = "spawnmonster",
              offset = { 0, 2 },
              type = entity.type(),
              arguments = parameters
            }
          }
        })
      end
    end
    -- SMARTPET END
  end
  entity.setDropPool(nil)
  return true
end

--------------------------------------------------------------------------------
function capturepod.isCaptive()
  return storage.ownerUuid ~= nil
end