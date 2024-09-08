require "/pat/classicquickbar/util.lua"

local qbBuilder = {}
_ENV.qbBuilder = qbBuilder

function qbBuilder.translateLegacyAction(item)
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

function qbBuilder.translateLegacyItems(iconConfig, translation)
  for k, tr in pairs(translation) do
    for _, item in ipairs(iconConfig[k] or {}) do
      local id = string.format("_legacy.%s:%s", k, item.label)
      iconConfig.items[id] = {
        label = (tr.prefix or "")..item.label,
        icon = item.icon,
        weight = tr.weight or 0,
        condition = tr.condition,
        action = qbBuilder.translateLegacyAction(item)
      }
    end
  end
end

function qbBuilder.getHiddenItems(itemTable)
  local hidden = qbUtil.getMetaguiSetting("pat_hiddenIcons", nil)

  if not hidden and itemTable then
    hidden = {}
    for k, item in pairs(itemTable) do
      hidden[k] = item.defaultHidden or nil
    end
  end

  return hidden or {}
end

function qbBuilder.getItems(filter)
  local qbConfig = root.assetJson("/pat/classicquickbar/classicquickbar.json")
  local iconConfig = root.assetJson("/quickbar/icons.json")
  local hiddenItems = qbBuilder.getHiddenItems(iconConfig.items)
  local itemList = {}

  qbBuilder.translateLegacyItems(iconConfig, qbConfig.legacyTranslation)

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