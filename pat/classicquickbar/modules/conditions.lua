local conditions = _ENV.conditions or {}
_ENV.conditions = conditions

function condition(id, ...)
  if conditions[id] then
    return conditions[id](...)
  end
  return false
end

conditions["not"] = function(...)
  return not condition(...)
end

function conditions.any(...)
  for _, c in pairs({...}) do
    if condition(table.unpack(c)) then return true end
  end
  return false
end

function conditions.all(...)
  for _, c in pairs({...}) do
    if not condition(table.unpack(c)) then return false end
  end
  return true
end

function conditions.admin()
  return player.isAdmin()
end

function conditions.statPositive(stat)
  return status.statPositive(stat)
end

function conditions.statNegative(stat)
  return not status.statPositive(stat)
end

function conditions.species(species)
  return player.species() == species
end

function conditions.ownShip()
  return player.worldId() == player.ownShipWorldId()
end

function conditions.recipe(name)
  return player.isAdmin() or player.blueprintKnown({name = name, count = 1})
end

function conditions.hasFlaggedItem(flag, value)
  return player.hasItemWithParameter(flag, value or true)
end

function conditions.hasTaggedItem(tag, count)
  local c = player.inventoryTags()[tag] or 0
  return c >= (count or 1)
end

function conditions.configExists(key)
  return pcall(root.assetJson, key)
end

function conditions.techExists(name)
  return root.hasTech(name)
end

function conditions.statusProperty(key, value)
  local p = status.statusProperty(key)
  if value == nil then
    return not not p
  end
  return compare(p, value)
end

function conditions.playerProperty(key, value)
  local p = player.getProperty(key)
  if value == nil then
    return not not p
  end
  return compare(p, value)
end
