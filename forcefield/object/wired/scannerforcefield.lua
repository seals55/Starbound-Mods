function init(virtual)
  if not virtual then
    entity.setInteractive(true)
    if storage.state == nil then
      output(false)
    else
      output(storage.state)
    end
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
  
  for i = -50, 50 do
    for a = -100,100 do
        sample = world.material(entity.toAbsolutePosition({a,i}), "background")
         if sample == "forcelayout" then
         world.placeMaterial(entity.toAbsolutePosition({ a, i }), "foreground", "forcefieldblock")
     --world.logInfo("terminamos de poner el bloque")
     end
    end
   end
 end
 
function destruir()
  --code to destroy the blocks
    for i = -50, 50 do
    for a = -100,100 do
        sample = world.material(entity.toAbsolutePosition({a,i}), "foreground")
         if sample == "forcefieldblock" then
         world.damageTiles({ entity.toAbsolutePosition({ a, i }) }, "foreground",entity.position(),"crushing", 9999)
     --world.logInfo("lo sacamos")
     end
    end
   end
 end