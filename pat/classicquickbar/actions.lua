actions = {}
qbActions = actions -- alias for compatibility

function actions.pane(cfg)
  if type(cfg) ~= "table" then cfg = { config = cfg } end
  player.interact(cfg.type or "ScriptPane", cfg.config)
end

function actions.ui(cfg, data) -- metaGUI windows
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = cfg, data = data })
end

function actions.exec(script, ...)
  if type(script) ~= "string" then return nil end
  params = {...} -- pass any given parameters to the script
  _SBLOADED[script] = nil require(script) -- force execute every time
  params = nil -- clear afterwards for cleanliness
end

function actions._legacy_module(s)
  local m, e = (function() local it = string.gmatch(s, "[^:]+") return it(), it() end)()
  local mf = string.format("/quickbar/%s.lua", m)
  module = { }
  _SBLOADED[mf] = nil require(mf) -- force execute
  module[e]() module = nil -- run function and clean up
end

local function nullfunc() end

function action(id, ...)
  return (actions[id] or nullfunc)(...)
end

function legacyAction(i)
  if i.pane then return { "pane", i.pane } end
  if i.scriptAction then
    sb.logInfo(string.format("Quickbar item \"%s\": scriptAction is deprecated, please use new entry format", i.label))
    return { "_legacy_module", i.scriptAction }
  end
  return { "null" }
end
