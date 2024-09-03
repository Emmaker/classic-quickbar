local shared = getmetatable''

function isMetaguiAvailable()
  local mgui = root.assetJson("/panes.config").metaGUI ~= nil
  isMetaguiAvailable = function() return mgui end
  return mgui
end

function getMetaguiSetting(key, default)
  local settings = player.getProperty("metagui:settings") or {}
  if not key then
    return settings
  end

  if settings[key] == nil then
    return default
  end
  return settings[key]
end

function setMetaguiSetting(key, value)
  if type(key) == "table" then
    return player.setProperty("metagui:settings", key)
  end
  local settings = getMetaguiSetting()
  settings[key] = value
  player.setProperty("metagui:settings", settings)
end

local function translateLegacyAction(item)
  if item.pane then return { "pane", item.pane } end

  if item.scriptAction then
    sb.logInfo(string.format("Quickbar item '%s': scriptAction is deprecated, please use new entry format", item.label))

    local match = string.gmatch(item.scriptAction, "[^:]+")
    local name, action = match(), match()
    local script = string.format("/quickbar/%s.lua", name)

    return { "_legacy_module", script, action }
  end
  
  return { "null" }
end

local function translateLegacyItems(iconConfig, translation)
  for k, tr in pairs(translation) do
    for _, item in ipairs(iconConfig[k] or {}) do
      local id = string.format("_legacy.%s:%s", k, item.label)
      iconConfig.items[id] = {
        label = (tr.prefix or "")..item.label,
        icon = item.icon,
        weight = tr.weight or 0,
        condition = tr.condition,
        action = translateLegacyAction(item)
      }
    end
  end
end

function getHiddenItems(itemTable)
  local hidden = getMetaguiSetting("pat_hiddenIcons", nil)

  if not hidden and itemTable then
    hidden = {}
    for k, item in pairs(itemTable) do
      hidden[k] = item.defaultHidden or nil
    end
  end

  return hidden or {}
end

function getQuickbarItems(filter)
  local qbConfig = root.assetJson("/pat/classicquickbar/classicquickbar.json")
  local iconConfig = root.assetJson("/quickbar/icons.json")
  local hiddenItems = getHiddenItems(iconConfig.items)
  local itemList = {}

  translateLegacyItems(iconConfig, qbConfig.legacyTranslation)

  for k, item in pairs(iconConfig.items) do
    item.id = k
    item.hidden = hiddenItems[k] or false
    if not filter or filter(item) then
      item.uncoloredLabel = string.gsub(item.label, "(%b^;)", "")
      item.label = string.gsub(item.label, "(%b^;)", qbConfig.colorTags)
      item.icon = item.icon or qbConfig.defaultImages.icon
      item.weight = item.weight or 0
      item._sort = item.uncoloredLabel:lower()

      if item.buttonImages then
        local set = item.buttonImages
        set.hover = set.hover or string.format(qbConfig.defaultImages.hover, set.base)
        set.pressed = set.pressed or string.format(qbConfig.defaultImages.pressed, set.base)
      end

      itemList[#itemList + 1] = item
    end
  end

  table.sort(itemList, function(a, b)
    return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort)
  end)

  return itemList, hiddenItems
end


function dismissStardustQB()
  if not isMetaguiAvailable() then
    return
  end

  local ipc = shared.metagui_ipc
  if not ipc or not ipc.uniqueByPath then
    return
  end

  local mguiQuickbarPath = root.assetJson("/metagui/registry.json:panes.quickbar.quickbar")

  return pcall(ipc.uniqueByPath[mguiQuickbarPath])
end

function dismissClassicQB()
  return pcall(shared.pat_classicqb_dismiss)
end

function openStardustQB()
  if not isMetaguiAvailable() or dismissStardustQB() then
    return
  end
  dismissClassicQB()

  player.interact("ScriptPane", { gui = {}, scripts = { "/metagui.lua" }, config = "quickbar:quickbar" })
  return true
end

local function getClassicQb()
  local qb = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
  local bg = qb.gui.background
  bg.fileBody = bg.fileBody_buttonless or bg.fileBody

  getClassicQb = function() return qb end
  return qb
end

function openClassicQB()
  if dismissClassicQB() then
    return
  end
  dismissStardustQB()

  player.interact("ScriptPane", getClassicQb())
  return true
end

function openQuickbar()
  if isMetaguiAvailable() and not getMetaguiSetting("pat_classicEnabled", true) then
    return openStardustQB()
  end
  return openClassicQB()
end

function dismissQuickbar()
  return dismissClassicQB() or dismissStardustQB()
end

function rebuildClassicQB()
  return pcall(shared.pat_classicqb_rebuild)
end
