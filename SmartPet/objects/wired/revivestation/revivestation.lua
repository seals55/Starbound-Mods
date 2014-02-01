function init(virtual)
  entity.setInteractive(true)
  if storage.countdown == nil then storage.countdown = 0 end
  self.hold = 0
  self.detectRadius = entity.configParameter("detectRadius")
  updateAnim()
end

function updateAnim()
  local state = "empty"
  if storage.petdata ~= nil then
    if storage.countdown > 31 then state = "new"
    elseif storage.countdown > 0 then state = "work"
    else state = "idle" end
  end
  entity.setAnimationState("itemState", state)
end

function die()
  if storage.petdata ~= nil then
    local type
    if storage.countdown > 0 then
      world.spawnItem("faintedcapturepod", entity.position(), 1, { memory = storage.petdata })
    else
      world.spawnItem("filledcapturepod", entity.position(), 1, {
        projectileConfig = {
          speed = 70,
          level = 7,
          actionOnReap = storage.petdata
        }
      })
    end
    storage.petdata = nil
  end
end

function onInteraction(args)
  die()
  self.hold = 20
  updateAnim()
end

function main()
  if self.hold > 0 then
    self.hold = self.hold - 1
  elseif storage.petdata == nil then
    local radius = self.detectRadius
    local drops = world.itemDropQuery(entity.position(), radius)
    if #drops > 0 then
      for i,v in pairs(drops) do
        if world.entityName(v) == "faintedcapturepod" then
          local item = world.takeItemDrop(v, entity.id())
          if item ~= nil then
            storage.petdata = item.data.memory
            storage.countdown = 51
            updateAnim()
            return
          end
        end
      end
      for i,v in pairs(drops) do
        if world.entityName(v) == "filledcapturepod" then
          local item = world.takeItemDrop(v, entity.id())
          if item ~= nil then
            storage.petdata = item.data.projectileConfig.actionOnReap
            storage.countdown = 0
            updateAnim()
            return
          end
        end
      end
    end
  elseif storage.countdown > 0 then
    storage.countdown = storage.countdown - 1
    if (storage.countdown == 46) or (storage.countdown == 0) then updateAnim()
    elseif storage.countdown == 31 then
      updateAnim()
      entity.playImmediateSound("/sfx/revivestation.wav")
    end
  end
end
