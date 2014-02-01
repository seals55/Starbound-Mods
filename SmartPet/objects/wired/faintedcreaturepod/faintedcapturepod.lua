function die()
  world.spawnItem("faintedcapturepod", entity.position(), 1, { memory = entity.configParameter("memory") })
end