local qbUtil = {}
_ENV.qbUtil = qbUtil

function qbUtil.isMetaguiAvailable()
  local mgui = root.assetJson("/panes.config").metaGUI ~= nil
  isMetaguiAvailable = function() return mgui end
  return mgui
end

function qbUtil.getMetaguiSetting(key, default)
  local settings = player.getProperty("metagui:settings") or {}
  if not key then
    return settings
  end

  if settings[key] == nil then
    return default
  end
  return settings[key]
end

function qbUtil.setMetaguiSetting(key, value)
  if type(key) == "table" then
    return player.setProperty("metagui:settings", key)
  end
  local settings = qbUtil.getMetaguiSetting()
  settings[key] = value
  player.setProperty("metagui:settings", settings)
end
