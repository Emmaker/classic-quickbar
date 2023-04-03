require "/scripts/util.lua"
require "/sys/quickbar/conditions.lua"

local actions = { }
qbActions = actions -- alias in global for execs
compactLabels = {}
local function nullfunc() end
local function action(id, ...) return (actions[id] or nullfunc)(...) end

-------------
-- actions --
-------------

function actions.pane(cfg)
  if type(cfg) ~= "table" then cfg = { config = cfg } end
  player.interact(cfg.type or "ScriptPane", cfg.config)
end

function actions.ui(cfg, data) -- metaGUI
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

---------------
-- internals --
---------------

local colorSub = { -- color tag substitutions
  ["^essential;"] = "^#ffb133;",
  ["^admin;"] = "^#bf7fff;",
  ["^pat_stardust;"] = "^#C6C4FF;",
}

local function legacyAction(i)
  if i.pane then return { "pane", i.pane } end
  if i.scriptAction then
    sb.logInfo(string.format("Quickbar item \"%s\": scriptAction is deprecated, please use new entry format", i.label))
    return { "_legacy_module", i.scriptAction }
  end
  return { "null" }
end

local function metaguiSettings(key, default)
  local settings = player.getProperty("metagui:settings", {})
  if settings[key] == nil then
    return default
  end
  return settings[key]
end

local function buildList()
  widget.clearListItems("scroll.list") -- clear out first
  local c = root.assetJson("/quickbar/icons.json")
  local items = { }
  
  -- stardust settings
  local settings = c.items["metagui:settings"]
  if settings then
    if metaguiSettings("pat_hideSettings", false) then
      c.items["metagui:settings"] = nil
    else
      settings.label = "^pat_stardust;Stardust "..settings.label
    end
  end
  
  --add stardust qb icon
  local starqb = config.getParameter("stardust_qb_icon")
  if starqb then table.insert(items, starqb) end
  
  for k, i in pairs(c.items) do -- dump in normal items
    if not i.condition or condition(table.unpack(i.condition)) then
      table.insert(items, i)
    end
  end
    
  -- and then translate legacy entries
  for _, i in pairs(c.priority) do
    table.insert(items, {
      label = "^essential;" .. i.label,
      icon = i.icon,
      weight = -1100,
      action = legacyAction(i)
    })
  end
  if player.isAdmin() then
    for _, i in pairs(c.admin) do
      table.insert(items, {
        label = "^admin;" .. i.label,
        icon = i.icon,
        weight = -1000,
        action = legacyAction(i),
        condition = { "admin" }
      })
    end
  end
  for _, i in pairs(c.normal) do
    table.insert(items, {
      label = i.label,
      icon = i.icon,
      action = legacyAction(i)
    })
  end
  
  -- sort by weight then alphabetically, ignoring caps and tags (and doing tag substitutions while we're here)
  for k, i in pairs(items) do
    i._sort = string.lower(string.gsub(i.label, "(%b^;)", ""))
    i.label = string.gsub(i.label, "(%b^;)", colorSub)
    i.weight = i.weight or 0
    --sb.logInfo("label: "..i.label.."\nsort: "..i._sort)
  end
  table.sort(items, function(a, b) return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort) end)
  
  -- and add items to pane list
  for idx = 1, #items do
    local i = items[idx]
    local l = "scroll.list." .. widget.addListItem("scroll.list")
    widget.setText(l .. ".label", i.label)
    local bc = l .. ".buttonContainer"
    widget.registerMemberCallback(bc, "click", function()
      if i.condition and not condition(table.unpack(i.condition)) then return nil end -- recheck condition on attempt
      action(table.unpack(i.action))

      if (metaguiSettings("quickbarAutoDismiss", true) and not i.blockAutoDismiss) or i.dismissQuickbar then pane.dismiss() end
    end)
    local btn = bc .. "." .. widget.addListItem(bc) .. ".button"
    widget.setButtonOverlayImage(btn, i.icon or "/items/currency/essence.png")
    
		compactLabels[btn] = i.label
  end
end

function init()
  --close stardust quickbar
  local ipc = getmetatable''.metagui_ipc
  if ipc and ipc.uniqueByPath and ipc.uniqueByPath["/sys/quickbar/build.lua"] then
    ipc.uniqueByPath["/sys/quickbar/build.lua"]()
    pane.dismiss()
    return
  end
  
  buildList()
end

function uninit()
  widget.clearListItems("scroll.list")
end
