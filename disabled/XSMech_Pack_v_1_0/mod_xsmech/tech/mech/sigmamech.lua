function init()
  data.active = false
  data.fireTimer = 0
  data.altFireTimer = 0
  data.altFireIntervalTimer = 0
  data.altFireCount = 0
  tech.setVisible(false)
  tech.rotateGroup("guns", 0, true)
  data.holdingJump = false
  data.holdingUp = false
  data.holdingDown = false
  data.holdingAltFire = false
  data.hoverTimer = 0
  data.bHasHovered = false
  data.bIsHovering = false
  data.fTracerCount = 0
  data.bTracerCount = 2
end

function uninit()
  if data.active then
    local mechTransformPositionChange = tech.parameter("mechTransformPositionChange")
    tech.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
    tech.setParentOffset({0, 0})
    data.active = false
    data.holdingJump = false
	data.holdingUp = false
	data.holdingDown = false
	data.holdingAltFire = false
    data.hoverTimer = 0
    data.bHasHovered = false
    data.bIsHovering = false
    tech.setVisible(false)
    tech.setParentAppearance("normal")
    tech.setToolUsageSuppressed(false)
    tech.setParentFacingDirection(nil)
  end
end

function input(args)
  -- Check if player is holding jump first
  if args.moves["jump"] then
    data.holdingJump = true
  elseif not args.moves["jump"] then
    data.holdingJump = false
  end
  
  if args.moves["up"] then
    data.holdingUp = true
  elseif not args.moves["up"] then
    data.holdingUp = false
  end
  
  if args.moves["down"] then
    data.holdingDown = true
  elseif not args.moves["down"] then
    data.holdingDown = false
  end
  
  if args.moves["altFire"] then
    data.holdingAltFire = true
  elseif not args.moves["altFire"] then
    data.holdingAltFire = false
  end

  if args.moves["special"] == 1 then
    if data.active then
      return "mechDeactivate"
    else
      return "mechActivate"
    end
  elseif args.moves["primaryFire"] then
    return "mechFire"
  end

  return nil
end

function math.sign(x)
  if x < 0 then
    return -1
  else
    return 1
  end
end

function update(args)
  local energyCostPerSecond = tech.parameter("energyCostPerSecond")
  local mechCustomMovementParameters = tech.parameter("mechCustomMovementParameters")
  local mechTransformPositionChange = tech.parameter("mechTransformPositionChange")
  local parentOffset = tech.parameter("parentOffset")
  local mechCollisionTest = tech.parameter("mechCollisionTest")
  local mechAimLimit = tech.parameter("mechAimLimit") * math.pi / 180
  local mechFrontRotationPoint = tech.parameter("mechFrontRotationPoint")
  local mechFrontFirePosition = tech.parameter("mechFrontFirePosition")
  local mechBackRotationPoint = tech.parameter("mechBackRotationPoint")
  local mechBackFirePosition = tech.parameter("mechBackFirePosition")
  local mechFireCycle = tech.parameter("mechFireCycle")
  local mechProjectile = tech.parameter("mechProjectile")
  local mechTracerProjectile = tech.parameter("mechTracerProjectile")
  local mechProjectileConfig = tech.parameter("mechProjectileConfig")
  
  local mechGunFireCone = tech.parameter("mechGunFireCone") * math.pi / 180
  
  local mechAltFireCycle = tech.parameter("mechAltFireCycle") 
  local mechAltProjectile = tech.parameter("mechAltProjectile")
  local mechAltProjectileConfig = tech.parameter("mechAltProjectileConfig")
  local mechAltFireShotInterval = tech.parameter("mechAltFireShotInterval")
  
  local mechHoverSpeed = tech.parameter("mechHoverSpeed")
  local mechHoverTime = tech.parameter("mechHoverTime")
  local mechHoverBuffer = tech.parameter("mechHoverBuffer")
  
  if not data.active and args.actions["mechActivate"] then
    mechCollisionTest[1] = mechCollisionTest[1] + tech.position()[1]
    mechCollisionTest[2] = mechCollisionTest[2] + tech.position()[2]
    mechCollisionTest[3] = mechCollisionTest[3] + tech.position()[1]
    mechCollisionTest[4] = mechCollisionTest[4] + tech.position()[2]
    if not world.rectCollision(mechCollisionTest) then
      tech.burstParticleEmitter("mechActivateParticles")
      tech.translate(mechTransformPositionChange)
      tech.setVisible(true)
      tech.setParentAppearance("sit")
      tech.setToolUsageSuppressed(true)
      data.active = true
    else
      -- Make some kind of error noise
    end
  elseif data.active and (args.actions["mechDeactivate"] or energyCostPerSecond * args.dt > args.availableEnergy) then
    tech.burstParticleEmitter("mechDeactivateParticles")
    tech.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
    tech.setVisible(false)
    tech.setParentAppearance("normal")
    tech.setToolUsageSuppressed(false)
    tech.setParentOffset({0, 0})
	
	tech.setAnimationState("hovering", "off")
	tech.setParticleEmitterActive("hoverParticles", false)
	data.holdingJump = false
    data.hoverTimer = 0
    -- data.bHasHovered = false
    data.bIsHovering = false
	
    data.active = false
  end

  tech.setParentFacingDirection(nil)
  if data.active then
    local diff = world.distance(args.aimPosition, tech.position())
    local aimAngle = math.atan2(diff[2], diff[1])
    local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2

    tech.applyMovementParameters(mechCustomMovementParameters)
    if flip then
      tech.setFlipped(true)
      local nudge = tech.stateNudge()
      tech.setParentOffset({-parentOffset[1] - nudge[1], parentOffset[2] + nudge[2]})
      tech.setParentFacingDirection(-1)

      if aimAngle > 0 then
        aimAngle = math.max(aimAngle, math.pi - mechAimLimit)
      else
        aimAngle = math.min(aimAngle, -math.pi + mechAimLimit)
      end

      tech.rotateGroup("guns", math.pi - aimAngle)
    else
      tech.setFlipped(false)
      local nudge = tech.stateNudge()
      tech.setParentOffset({parentOffset[1] + nudge[1], parentOffset[2] + nudge[2]})
      tech.setParentFacingDirection(1)

      if aimAngle > 0 then
        aimAngle = math.min(aimAngle, mechAimLimit)
      else
        aimAngle = math.max(aimAngle, -mechAimLimit)
      end

      tech.rotateGroup("guns", aimAngle)
    end

    if not tech.onGround() then
      if tech.velocity()[2] > 0 and not bIsHovering then
        tech.setAnimationState("movement", "jump")
	  elseif tech.velocity()[2] <= 0 and data.holdingJump and not data.bHasHovered then
	    -- Activate hovering
	    data.bIsHovering = true
		data.hoverTimer = mechHoverTime
		data.bHasHovered = true
	  elseif data.bIsHovering and data.hoverTimer > 0 then
	    -- Maintain hovering
		tech.setAnimationState("movement", "jump")
		if data.holdingUp and not data.holdingDown then
		  tech.yControl(1, 1000, true)
		elseif data.holdingDown and not data.holdingUp then
	      tech.yControl(-0.1, 1000, true)
		else
		  tech.yControl(mechHoverSpeed, 1000, true)
		end		
		
		-- Hover Timer
		data.hoverTimer = data.hoverTimer - args.dt		
		
		if data.hoverTimer < mechHoverTime - mechHoverBuffer and data.holdingJump then
			-- Deactivate hovering after buffer timer if jump is still pressed
			data.hoverTimer = 0
			data.bIsHovering = false
			tech.setAnimationState("movement", "fall")	
		end
		
	  elseif data.bIsHovering and data.hoverTimer <= 0 then
		-- Deactivate hovering if hover time runs out
		data.hoverTimer = 0
		data.bIsHovering = false
		tech.setAnimationState("movement", "fall")	
      else
        tech.setAnimationState("movement", "fall")
      end
	elseif tech.onGround() and data.bHasHovered then
	  -- Deactivate hovering if on the ground, reset hover ability
	  data.bHasHovered = false
	  data.bIsHovering = false
    elseif tech.walking() or tech.running() then
      if data.bIsHovering then
	    -- Deactivate hovering if walking/running
		data.hoverTimer = 0
		data.bIsHovering = false
		data.bHasHovered = false
	  end 
	  if flip and tech.direction() == 1 or not flip and tech.direction() == -1 then
        tech.setAnimationState("movement", "backWalk")
      else
        tech.setAnimationState("movement", "walk")
      end
    else
      tech.setAnimationState("movement", "idle")
    end
	
	-- If hovering, activate hover animations, sound, and particle effects. Otherwise deactivate.
	if data.bIsHovering then
      tech.setAnimationState("hovering", "on")
      tech.setParticleEmitterActive("hoverParticles", true)
    else
      tech.setAnimationState("hovering", "off")
      tech.setParticleEmitterActive("hoverParticles", false)
    end

	-- Primary weapon system (Miniguns)
    if args.actions["mechFire"] then
      if data.fireTimer <= 0 then
	    local fireAngle = aimAngle - mechGunFireCone + math.random() * 2 * mechGunFireCone       		
		-- Front Gun Tracer Counter
		if data.fTracerCount < 4 then
		  world.spawnProjectile(mechProjectile, tech.anchorPoint("frontGunFirePoint"), tech.parentEntityId(), {math.cos(fireAngle), math.sin(fireAngle)}, false, mechProjectileConfig)
          data.fTracerCount = data.fTracerCount + 1
		else
		  world.spawnProjectile(mechTracerProjectile, tech.anchorPoint("frontGunFirePoint"), tech.parentEntityId(), {math.cos(fireAngle), math.sin(fireAngle)}, false, mechProjectileConfig)
		  data.fTracerCount = 0
		end
		data.fireTimer = data.fireTimer + mechFireCycle
        tech.setAnimationState("frontFiring", "fire")
		tech.setAnimationState("frontRecoil", "fire")
		tech.playImmediateSound("/sfx/gun/uzi3.wav")
      else
        local oldFireTimer = data.fireTimer
        data.fireTimer = data.fireTimer - args.dt
        if oldFireTimer > mechFireCycle / 2 and data.fireTimer <= mechFireCycle / 2 then
          local fireAngle = aimAngle - mechGunFireCone + math.random() * 2 * mechGunFireCone
		  -- Back Gun Tracer Counter
		  if data.bTracerCount < 4 then
		    world.spawnProjectile(mechProjectile, tech.anchorPoint("backGunFirePoint"), tech.parentEntityId(), {math.cos(fireAngle), math.sin(fireAngle)}, false, mechProjectileConfig)
            data.bTracerCount = data.bTracerCount + 1
		  else
		    world.spawnProjectile(mechTracerProjectile, tech.anchorPoint("backGunFirePoint"), tech.parentEntityId(), {math.cos(fireAngle), math.sin(fireAngle)}, false, mechProjectileConfig)
            data.bTracerCount = 0
		  end		  
		  tech.setAnimationState("backFiring", "fire")
		  tech.setAnimationState("backRecoil", "fire")
		  tech.playImmediateSound("/sfx/gun/uzi1.wav")
        end
      end
    end

	-- Secondary weapon system (Missile Pod)
	if data.altFireTimer <= 0 and data.altFireCount <= 0 then
	  tech.setAnimationState("missilePodRecoil", "off")
      if data.holdingAltFire then
	    -- Prime pod for firing
	    data.altFireIntervalTimer = 0 -- mechAltFireShotInterval
	    data.altFireCount = 1
		data.altFireTimer = mechAltFireCycle
	  end
	elseif data.altFireTimer <= 1.0 and data.altFireCount >= 5 then
	  -- Reloading animation, reset weapon system
	  tech.setAnimationState("missilePodRecoil", "reload")
	  -- tech.playImmediateSound("/sfx/gun/rocket_reload_clip3.wav")
	  data.altFireCount = 0
	end
	-- Advance Timers
	if data.altFireTimer > 0 then
	  data.altFireTimer = data.altFireTimer - args.dt
	end	
	if data.altFireIntervalTimer > 0 then
	  data.altFireIntervalTimer = data.altFireIntervalTimer - args.dt	
	end
    -- Missile barrage	
	if data.altFireIntervalTimer <= 0 and data.altFireCount > 0 and data.altFireCount < 5 then
	  data.altFireIntervalTimer = mechAltFireShotInterval
	  if data.altFireCount == 1 then
	    world.spawnProjectile(mechAltProjectile, tech.anchorPoint("missilePodFirePoint1"), tech.parentEntityId(), {math.sign(math.cos(aimAngle)) * 0.754, 0.656}, false, mechAltProjectileConfig)
        tech.setAnimationState("missilePodRecoil", "fire1")
		tech.playImmediateSound("/sfx/gun/grenade1.wav")	
	  elseif data.altFireCount == 2 then
	    world.spawnProjectile(mechAltProjectile, tech.anchorPoint("missilePodFirePoint2"), tech.parentEntityId(), {math.sign(math.cos(aimAngle)) * 0.731, 0.682}, false, mechAltProjectileConfig)
        tech.setAnimationState("missilePodRecoil", "fire2")
		tech.playImmediateSound("/sfx/gun/grenade1.wav")	
	  elseif data.altFireCount == 3 then
	    world.spawnProjectile(mechAltProjectile, tech.anchorPoint("missilePodFirePoint3"), tech.parentEntityId(), {math.sign(math.cos(aimAngle)) * 0.707, 0.707}, false, mechAltProjectileConfig)
        tech.setAnimationState("missilePodRecoil", "fire3")
		tech.playImmediateSound("/sfx/gun/grenade1.wav")		
	  elseif data.altFireCount == 4 then
	    world.spawnProjectile(mechAltProjectile, tech.anchorPoint("missilePodFirePoint4"), tech.parentEntityId(), {math.sign(math.cos(aimAngle)) * 0.682, 0.731}, false, mechAltProjectileConfig)
        tech.setAnimationState("missilePodRecoil", "fire4")
		tech.playImmediateSound("/sfx/gun/grenade1.wav")	
	  end
	  data.altFireCount = data.altFireCount + 1
	end

    return energyCostPerSecond * args.dt
  end

  return 0
end
