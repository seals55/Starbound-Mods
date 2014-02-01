function checkCollision(position)
  local collisionBounds = tech.collisionBounds()
  collisionBounds[1] = collisionBounds[1] - tech.position()[1] + position[1]
  collisionBounds[2] = collisionBounds[2] - tech.position()[2] + position[2]
  collisionBounds[3] = collisionBounds[3] - tech.position()[1] + position[1]
  collisionBounds[4] = collisionBounds[4] - tech.position()[2] + position[2]

  return not world.rectCollision(collisionBounds)
end

function blinkAdjust(position, doPathCheck, doCollisionCheck, doLiquidCheck, doStandCheck)
  local blinkCollisionCheckDiameter = tech.parameter("blinkCollisionCheckDiameter")
  local blinkVerticalGroundCheck = tech.parameter("blinkVerticalGroundCheck")
  local blinkFootOffset = tech.parameter("blinkFootOffset")

  if doPathCheck then
    local collisionBlocks = world.collisionBlocksAlongLine(tech.position(), position, true, 1)
    if #collisionBlocks ~= 0 then
      local diff = world.distance(position, tech.position())
      diff[1] = diff[1] / math.abs(diff[1])
      diff[2] = diff[2] / math.abs(diff[2])

      position = {collisionBlocks[1][1] - diff[1], collisionBlocks[1][2] - diff[2]}
    end
  end

  if doCollisionCheck and not checkCollision(position) then
    local spaceFound = false
    for i = 1, blinkCollisionCheckDiameter * 2 do
      if checkCollision({position[1] + i / 2, position[2] + i / 2}) then
        position = {position[1] + i / 2, position[2] + i / 2}
        spaceFound = true
        break
      end

      if checkCollision({position[1] - i / 2, position[2] + i / 2}) then
        position = {position[1] - i / 2, position[2] + i / 2}
        spaceFound = true
        break
      end

      if checkCollision({position[1] + i / 2, position[2] - i / 2}) then
        position = {position[1] + i / 2, position[2] - i / 2}
        spaceFound = true
        break
      end

      if checkCollision({position[1] - i / 2, position[2] - i / 2}) then
        position = {position[1] - i / 2, position[2] - i / 2}
        spaceFound = true
        break
      end
    end

    if not spaceFound then
      return nil
    end
  end

  if doStandCheck then
    local groundFound = false 
    for i = 1, blinkVerticalGroundCheck * 2 do
      local checkPosition = {position[1], position[2] - i / 2}

      if world.pointCollision(checkPosition, false) then
        groundFound = true
        position = {checkPosition[1], checkPosition[2] + 0.5 - blinkFootOffset}
        break
      end
    end

    if not groundFound then
      return nil
    end
  end

  if doLiquidCheck and (world.liquidAt(position) or world.liquidAt({position[1], position[2] + blinkFootOffset})) then
    return nil
  end

  if doCollisionCheck and not checkCollision(position) then
    return nil
  end

  return position
end

function findRandomBlinkLocation(doCollisionCheck, doLiquidCheck, doStandCheck)
  local randomBlinkTries = tech.parameter("randomBlinkTries")
  local randomBlinkDiameter = tech.parameter("randomBlinkDiameter")

  for i=1,randomBlinkTries do
    local position = tech.position()
    position[1] = position[1] + (math.random() * 2 - 1) * randomBlinkDiameter
    position[2] = position[2] + (math.random() * 2 - 1) * randomBlinkDiameter

    local position = blinkAdjust(position, false, doCollisionCheck, doLiquidCheck, doStandCheck)
    if position then
      return position
    end
  end

  return nil
end

function uninit()
  tech.setParentAppearance("normal")
end

function init()
  data.multiJumps = 0
  data.lastJump = false
  data.mode = "none"
  data.timer = 0
  data.targetPosition = nil
  data.airDashing = false
  data.dashTimer = 0
  data.dashDirection = 0
  data.dashLastInput = 0
  data.dashTapLast = 0
  data.dashTapTimer = 0
  data.lastBoost = nil
  data.ranOut = false
end

function input(args)
  local currentJump = args.moves["jump"]
  local currentBoost = nil

  if args.moves["jump"] and not tech.jumping() and not tech.canJump() and not data.lastJump and data.multiJumps < tech.parameter("multiJumpCount") then
    data.lastJump = true
    return "multiJump"
  elseif args.moves["special"] == 1 then
    return "blink"
  elseif args.moves["jump"] and not tech.onGround() then
	world.logInfo("here1")
    if not tech.canJump() and currentJump and not data.lastJump then
      if args.moves["right"] and args.moves["up"] then
        currentBoost = "boostRightUp"
      elseif args.moves["right"] and args.moves["down"] then
        currentBoost = "boostRightDown"
      elseif args.moves["left"] and args.moves["up"] then
        currentBoost = "boostLeftUp"
      elseif args.moves["left"] and args.moves["down"] then
        currentBoost = "boostLeftDown"
      elseif args.moves["right"] then
        currentBoost = "boostRight"
      elseif args.moves["down"] then
        currentBoost = "boostDown"
      elseif args.moves["left"] then
        currentBoost = "boostLeft"
      elseif args.moves["up"] then
        currentBoost = "boostUp"
      end
    elseif currentJump and data.lastBoost then
      currentBoost = data.lastBoost
    end
	data.lastJump = currentJump
	data.lastBoost = currentBoost
	return currentBoost
  else
    --data.lastJump = args.moves["jump"]
	data.lastJump = currentJump
	data.lastBoost = currentBoost
	if data.dashTimer > 0 then
      return nil
    end

    local maximumDoubleTapTime = tech.parameter("maximumDoubleTapTime")

    if data.dashTapTimer > 0 then
      data.dashTapTimer = data.dashTapTimer - args.dt
    end

    if args.moves["right"] then
      if data.dashLastInput ~= 1 then
        if data.dashTapLast == 1 and data.dashTapTimer > 0 then
          data.dashTapLast = 0
          data.dashTapTimer = 0
          return "dashRight"
        else
          data.dashTapLast = 1
          data.dashTapTimer = maximumDoubleTapTime
        end
      end
      data.dashLastInput = 1
    elseif args.moves["left"] then
      if data.dashLastInput ~= -1 then
        if data.dashTapLast == -1 and data.dashTapTimer > 0 then
          data.dashTapLast = 0
          data.dashTapTimer = 0
          return "dashLeft"
        else
          data.dashTapLast = -1
          data.dashTapTimer = maximumDoubleTapTime
        end
      end
      data.dashLastInput = -1
    else
      data.dashLastInput = 0
    end
      return nil
  end
end

function update(args)
  local multiJumpCount = tech.parameter("multiJumpCount")
  local energyUsage = tech.parameter("energyUsage")
  local blinkMode = tech.parameter("blinkMode")
  local blinkOutTime = tech.parameter("blinkOutTime")
  local blinkInTime = tech.parameter("blinkInTime")
  
  local dashControlForce = tech.parameter("dashControlForce")
  local dashSpeed = tech.parameter("dashSpeed")
  local dashDuration = tech.parameter("dashDuration")
  --local energyUsage = tech.parameter("energyUsage")
  
  local boostControlForce = tech.parameter("boostControlForce")
  local boostSpeed = tech.parameter("boostSpeed")
  local energyUsagePerSecond = tech.parameter("energyUsagePerSecond")
  local energyUsageBoost = energyUsagePerSecond * args.dt

  local usedEnergy = 0
  
  if args.availableEnergy < energyUsageBoost then
    data.ranOut = true
  elseif tech.onGround() or tech.inLiquid() then
    data.ranOut = false
  end
  
  local boosting = false
  local diag = 1 / math.sqrt(2)
  
  if args.actions["blink"] and data.mode == "none" and args.availableEnergy > energyUsage then
    local blinkPosition = nil
    if blinkMode == "random" then
      local randomBlinkAvoidCollision = tech.parameter("randomBlinkAvoidCollision")
      local randomBlinkAvoidMidair = tech.parameter("randomBlinkAvoidMidair")
      local randomBlinkAvoidLiquid = tech.parameter("randomBlinkAvoidLiquid")

      blinkPosition =
        findRandomBlinkLocation(randomBlinkAvoidCollision, randomBlinkAvoidMidair, randomBlinkAvoidLiquid) or
        findRandomBlinkLocation(randomBlinkAvoidCollision, randomBlinkAvoidMidair, false) or
        findRandomBlinkLocation(randomBlinkAvoidCollision, false, false)
    elseif blinkMode == "cursor" then
      blinkPosition = blinkAdjust(args.aimPosition, true, true, false, false)
    elseif blinkMode == "cursorPenetrate" then
      blinkPosition = blinkAdjust(args.aimPosition, false, true, false, false)
    end

    if blinkPosition then
      data.targetPosition = blinkPosition
      data.mode = "start"
    else
      -- Make some kind of error noise
    end
  end
  
    
  if data.mode == "start" then
    tech.setVelocity({0, 0})
    data.mode = "out"
    data.timer = 0

    return energyUsage
  elseif data.mode == "out" then
    tech.setParentAppearance("hidden")
    tech.setAnimationState("blinking", "out")
    tech.setVelocity({0, 0})
    data.timer = data.timer + args.dt

    if data.timer > blinkOutTime then
      tech.setPosition(data.targetPosition)
      data.mode = "in"
      data.timer = 0
    end

    return 0
  elseif data.mode == "in" then
    tech.setParentAppearance("normal")
    tech.setAnimationState("blinking", "in")
    tech.setVelocity({0, 0})
    data.timer = data.timer + args.dt

    if data.timer > blinkInTime then
      data.mode = "none"
    end

    return 0
  end
  
  if args.actions["multiJump"] and data.multiJumps < multiJumpCount and args.availableEnergy > energyUsage then
    tech.jump(true)
    data.multiJumps = data.multiJumps + 1
    tech.burstParticleEmitter("multiJumpParticles")
    tech.playImmediateSound(tech.parameter("jumpsound"))
    return energyUsage
  else
    if tech.onGround() or tech.inLiquid() then
      data.multiJumps = 0
    end
    --return 0.0
  end
  
  if not data.ranOut then
    boosting = true
    if args.actions["boostRightUp"] then
      tech.control({boostSpeed * diag, boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostRightDown"] then
      tech.control({boostSpeed * diag, -boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostLeftUp"] then
      tech.control({-boostSpeed * diag, boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostLeftDown"] then
      tech.control({-boostSpeed * diag, -boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostRight"] then
      tech.control({boostSpeed, 0}, boostControlForce, true, true)
    elseif args.actions["boostDown"] then
      tech.control({0, -boostSpeed}, boostControlForce, true, true)
    elseif args.actions["boostLeft"] then
      tech.control({-boostSpeed, 0}, boostControlForce, true, true)
    elseif args.actions["boostUp"] then
      tech.control({0, boostSpeed}, boostControlForce, true, true)
    else
      boosting = false
    end
  end
  
  if boosting then
    tech.setAnimationState("boosting", "on")
    tech.setParticleEmitterActive("boostParticles", true)
    return energyUsageBoost
  else
    tech.setAnimationState("boosting", "off")
    tech.setParticleEmitterActive("boostParticles", false)
  end
  
  local dashed = 0 --need a flag to tell if we've dashed
  if args.actions["dashRight"] and data.dashTimer <= 0 and args.availableEnergy > energyUsage then
    data.dashTimer = dashDuration
    data.dashDirection = 1
	dashed = 1
    usedEnergy = energyUsage
    data.airDashing = not tech.onGround()
  elseif args.actions["dashLeft"] and data.dashTimer <= 0 and args.availableEnergy > energyUsage then
    data.dashTimer = dashDuration
    data.dashDirection = -1
	dashed = 1
    usedEnergy = energyUsage
    data.airDashing = not tech.onGround()
  end

  if data.dashTimer > 0 then
    tech.xControl(dashSpeed * data.dashDirection, dashControlForce, true)

    if data.airDashing then
      tech.applyMovementParameters({gravityEnabled = false})
      tech.yControl(0, dashControlForce, true)
    end

    if data.dashDirection == -1 then
      tech.moveLeft()
      tech.setFlipped(true)
    else
      tech.moveRight()
      tech.setFlipped(false)
    end
    tech.setAnimationState("dashing", "on")
    tech.setParticleEmitterActive("dashParticles", true)
    data.dashTimer = data.dashTimer - args.dt
  else
    tech.setAnimationState("dashing", "off")
    tech.setParticleEmitterActive("dashParticles", false)
  end
  
  if dashed == 1 then
     return usedEnergy
  else
     return 0.0
  end
  
  --elseif args.actions["blink"] and data.mode == "none" and args.availableEnergy > energyUsage then
end
