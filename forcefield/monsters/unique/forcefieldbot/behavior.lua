function init(args)
  self.dead = false
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "moveState",
    "fleeState",
    "dieState"
  })
  self.state.leavingState = function(stateName)
    entity.setAnimationState("movement", "idle")
    entity.setRunning(false)
  end

  entity.setAggressive(false)
  entity.setAnimationState("movement", "idle")
--code to create the blocks
  --spherical thingy by Quatroking
  world.logInfo("Building shield...")
  n = -3
  m = 3
  l = 1
  for i = -3, 6 do
  l = l + 1
  world.logInfo(l)
  if l == 11 then
    i = i - 1
        world.logInfo("i is currently: ")
        world.logInfo(i)
        n = n + 1
        m = m - 1
        world.placeMaterial(entity.toAbsolutePosition({ n, i }), "foreground", "lightforcefieldblock")
        world.logInfo("check 1")
    world.placeMaterial(entity.toAbsolutePosition({ m, i }), "foreground", "lightforcefieldblock")
        world.logInfo("check 2")
        i = i + 1
  else
    world.placeMaterial(entity.toAbsolutePosition({ n, i }), "foreground", "lightforcefieldblock")
    world.placeMaterial(entity.toAbsolutePosition({ m, i }), "foreground", "lightforcefieldblock")
  end
  if l <= 4 then
    n = n - 1
    m = m + 1
  end
  if l == 6 or l == 8 or l == 9 then
    n = n + 1
    m = m - 1
  end
 
  end
  for i = -1, 1 do
  world.placeMaterial(entity.toAbsolutePosition({ i, 6 }), "foreground", "lightforcefieldblock")
  end
  world.logInfo("Shield finished")
 end

function main()
  self.state.update(entity.dt())
  self.sensors.clear()
end

function damage(args)
  if entity.health() <= 1 then
    self.state.pickState({ die = true })
  else
    self.state.pickState({ targetId = args.sourceId })
  end
end

function shouldDie()
  return self.dead
end

function move(direction)
  entity.setFacingDirection(direction)
  if direction < 0 then
    entity.moveLeft()
  else
    entity.moveRight()
  end
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  local direction
  if math.random(100) > 50 then
    direction = 0
  else
    direction = 0
  end

  return {
    timer = entity.randomizeParameterRange("moveTimeRange"),
    direction = direction
  }
end

function moveState.update(dt, stateData)
  if self.sensors.blockedSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  entity.setAnimationState("movement", "move")
  move(stateData.direction)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, 1.0
  end

  return false
end

--------------------------------------------------------------------------------
fleeState = {}

function fleeState.enterWith(args)
  if args.die then return nil end
  if args.targetId == nil then return nil end
  if self.state.stateDesc() == "fleeState" then return nil end

  return {
    targetId = args.targetId,
    timer = entity.configParameter("fleeMaxTime"),
    distance = entity.randomizeParameterRange("fleeDistanceRange")
  }
end

function fleeState.update(dt, stateData)
  entity.setRunning(true)
  entity.setAnimationState("movement", "run")

  local targetPosition = world.entityPosition(stateData.targetId)
  if targetPosition ~= nil then
    local toTarget = world.distance(targetPosition, entity.position())
    if world.magnitude(toTarget) > stateData.distance then
      return true
    else
      stateData.direction = -toTarget[1]
    end
  end

  if stateData.direction ~= nil then
    move(stateData.direction)
  else
    return true
  end

  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0
end

--------------------------------------------------------------------------------
dieState = {}

function dieState.enterWith(args)
  if not args.die then return nil end
  if self.state.stateDesc() == "dieState" then return nil end

  return {}
end

function dieState.update(dt, stateData)
  local animationState = entity.animationState("movement")
  if animationState == "invisible" then
    self.dead = true
  elseif animationState ~= "die" then
    for i = -7, 7 do
    for a = -7,7 do
        sample = world.material(entity.toAbsolutePosition({a,i}), "foreground")
         if sample == "lightforcefieldblock" then
         world.damageTiles({ entity.toAbsolutePosition({ a, i }) }, "foreground",entity.position(),"crushing", 9999)
     --world.logInfo("lo sacamos")
     end
    end
   end
    entity.setAnimationState("movement", "die")
  end

  return false
end
