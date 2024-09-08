require "/pat/classicquickbar/util.lua"

local actions = _ENV.actions or {}
_ENV.actions = actions

function action(id, ...)
  if actions[id] then
    return actions[id](...)
  end
end

function actions.pane(cfg)
  if type(cfg) ~= "table" then cfg = { config = cfg } end
  player.interact(cfg.type or "ScriptPane", cfg.config)
end

function actions.ui(cfg, data, fallback)
  player.interact("ScriptPane", { gui = {}, scripts = {"/metagui.lua"}, config = cfg, data = data, fallback = fallback })
end

function actions.exec(script, ...)
  if type(script) ~= "string" then return nil end
  params = {...}
  _SBLOADED[script] = nil
  require(script)
  params = nil
end

function actions._legacy_module(script, action)
  if type(script) ~= "string" or type(action) ~= "string" then return nil end
  module = {}
  _SBLOADED[script] = nil
  require(script)
  if module[action] then module[action]() end
  module = nil
end

function actions.changeMode()
  local compact = qbUtil.getMetaguiSetting("pat_compactQuickbar", false)
  qbUtil.setMetaguiSetting("pat_compactQuickbar", not compact)
  qbManager.rebuildClassic()
end
