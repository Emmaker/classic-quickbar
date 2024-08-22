local shared = getmetatable''

function getMetaguiSetting(key, default)
  local settings = player.getProperty("metagui:settings") or {}
  if settings[key] == nil then
    return default
  end
  return settings[key]
end

local function translateLegacyAction(item)
  if item.pane then return { "pane", item.pane } end
  if item.scriptAction then
    sb.logInfo(string.format("Quickbar item '%s': scriptAction is deprecated, please use new entry format", item.label))
    return { "_legacy_module", item.scriptAction }
  end
  return { "null" }
end

local function translateLegacyItems(iconConfig, translation)
  for k, tr in pairs(translation) do
    for _, item in ipairs(iconConfig[k]) do
      local id = string.format("_legacy.%s:%s", k, item.label)
      iconConfig.items[id] = {
        label = (tr.prefix or "")..item.label,
        icon = item.icon,
        weight = tr.weight or 0,
        action = translateLegacyAction(item)
      }
    end
  end
end

local function getHiddenItems(itemTable)
  local hidden = getMetaguiSetting("pat_hiddenIcons", nil)

  if not hidden and itemTable then
    hidden = { }
    for k, item in pairs(itemTable) do
      hidden[k] = item.defaultHidden or nil
    end
  end

  return hidden or { }
end

function getQuickbarItems(filter)
  local qbConfig = root.assetJson("/pat/classicquickbar/classicquickbar.json")
  local iconConfig = root.assetJson("/quickbar/icons.json")
  local hiddenItems = getHiddenItems(iconConfig.items)
  local itemList = { }

  translateLegacyItems(iconConfig, qbConfig.legacyTranslation)

  for k, item in pairs(iconConfig.items) do
    if not filter or filter(item, hiddenItems[k]) then
      item.id = k
      item.hidden = hiddenItems[k] or false
      item.label = string.gsub(item.label, "(%b^;)", qbConfig.colorTags)
      item.uncoloredLabel = string.gsub(item.label, "(%b^;)", "")
      item._sort = item.uncoloredLabel:lower()
      item.icon = item.icon or "/items/currency/essence.png"
      item.weight = item.weight or 0
      itemList[#itemList + 1] = item
    end
  end

  table.sort(itemList, function(a, b)
    return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort)
  end)

  return itemList, hiddenItems
end


function dismissStardustQB()
  local ipc = shared.metagui_ipc
  if not ipc or not ipc.uniqueByPath then
    return
  end

  local mguiQuickbarPath = root.assetJson("/metagui/registry.json:panes.quickbar.quickbar")
  if ipc.uniqueByPath[mguiQuickbarPath] then
    ipc.uniqueByPath[mguiQuickbarPath]()
    return true
  end
end

function dismissClassicQB()
  if shared.pat_classicqb_dismiss then
    shared.pat_classicqb_dismiss()
    return true
  end
end

function openStardustQB()
  if dismissStardustQB() then
    return
  end
  dismissClassicQB()

  player.interact("ScriptPane", { gui = { }, scripts = { "/metagui.lua" }, config = "quickbar:quickbar" })
  return true
end

function openClassicQB()
  if dismissClassicQB() then
    return
  end
  dismissStardustQB()

  local qb = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
  local bg = qb.gui.background
  bg.fileBody = bg.fileBody_buttonless or bg.fileBody
  player.interact("ScriptPane", qb)

  return true
end

function openQuickbar()
  if getMetaguiSetting("pat_classicEnabled", true) then
    return openClassicQB()
  else
    return openStardustQB()
  end
end

function dismissQuickbar()
  return dismissClassicQB() or dismissStardustQB()
end
