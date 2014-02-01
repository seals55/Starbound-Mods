function init(args)
  entity.setInteractive(true)
  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end
end
 
function onInteraction(args)
  output(not storage.state)
end
 
function output(state)
  if storage.state ~= state then
    storage.state = state
    if state then
      construir()
      entity.setAnimationState("switchState", "on")
      entity.playSound("onSounds");
    else
      destruir()
      entity.setAnimationState("switchState", "off")
      entity.playSound("offSounds");
    end
  else
  end
end
 
function construir()
  --code to create the blocks
  for i = -20, 20 do
  world.placeMaterial(entity.toAbsolutePosition({ 20, i }), "foreground", "forcefieldblock")
  world.placeMaterial(entity.toAbsolutePosition({ -20, i }), "foreground", "forcefieldblock")
  end
  for i = -20, 20 do
  world.placeMaterial(entity.toAbsolutePosition({ i, 20 }), "foreground", "forcefieldblock")
  --world.logInfo("terminamos de poner el bloque")
  end
 end
 
function destruir()
  --code to destroy the blocks
  for i = -20, 20 do
     sample = world.material(entity.toAbsolutePosition({ 20, i }), "foreground")
	 --world.logInfo(string.format("sample %s with data:", sample))
     if sample == "forcefieldblock" then
     local succes = world.damageTiles({ entity.toAbsolutePosition({ 20, i }) }, "foreground",entity.position(),"crushing", 9999)
	 if succes then
	 --world.logInfo("abc")
	 end
	 --world.logInfo("lo sacamos")
  end
  end
  for i = -20, 20 do
     sample = world.material(entity.toAbsolutePosition({ -20, i }), "foreground")
	 world.logInfo(string.format("sample %s with data::", sample))
     if sample == "forcefieldblock" then
     local succes = world.damageTiles({ entity.toAbsolutePosition({ -20, i }) }, "foreground",entity.position(),"crushing", 9999)
	 if succes then
	 --world.logInfo("abc")
	 end
	 --world.logInfo("lo sacamos")
     end
  end
  for i = -20, 20 do
     sample = world.material(entity.toAbsolutePosition({ i, 20 }), "foreground")
	 world.logInfo(string.format("sample %s with data::", sample))
     if sample == "forcefieldblock" then
     local succes = world.damageTiles({ entity.toAbsolutePosition({ i, 20 }) }, "foreground",entity.position(),"crushing", 9999)
	 if succes then
	 --world.logInfo("abc")
	 end
	 --world.logInfo("lo sacamos")
     end
   end
end

function die()
destruir()
end

