require "/pat/classicquickbar/shared.lua"
require "/pat/classicquickbar/actions.lua"
require "/sys/quickbar/conditions.lua"
conditions.pat_classicQuickbar = function() return true end

local hoverTooltips = { }
local tooltipsEnabled = false

local function buildList()
  widget.removeChild("scroll", "list")
  local listWidgets = config.getParameter("listWidgets")
  local compact = getMetaguiSetting("pat_compactQuickbar", false)
  widget.addChild("scroll", listWidgets[compact and "compact" or "default"], "list")
  widget.clearListItems("scroll.list")

  local iconConfig = root.assetJson("/quickbar/icons.json")
  local items = { }
  hoverTooltips = { }

  local listData = widget.getData("scroll.list") or {}
  tooltipsEnabled = listData.tooltips

  -- translate legacy entries
  for k, tr in pairs(iconConfig.legacyTranslation) do
    for _, item in ipairs(iconConfig[k]) do
      local id = string.format("_legacy.%s:%s", k, item.label)
      iconConfig.items[id] = {
        label = (tr.prefix or "")..item.label,
        icon = item.icon..(tr.directives or ""),
        weight = tr.weight or 0,
        action = legacyAction(item)
      }
    end
  end
  
  local hiddenItems = getMetaguiSetting("pat_hiddenIcons", {})
  
  for k, item in pairs(iconConfig.items) do
    if (item.unhideable or not hiddenItems[k]) and (not item.condition or condition(table.unpack(item.condition))) then
      local label = item.classicLabel or item.label
      item._sort = string.gsub(label, "(%b^;)", ""):lower()
      item.label = string.gsub(label, "(%b^;)", iconConfig.colorTags)
      item.weight = item.weight or 0
      table.insert(items, item)
    end
  end
  
  table.sort(items, function(a, b) return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort) end)
  
  for _, item in ipairs(items) do
    addQuickbarItem(item)
  end
end

local function itemCallback(item)
  if item.condition and not condition(table.unpack(item.condition)) then -- recheck condition on attempt
    pane.playSound("/sfx/interface/clickon_error.ogg")
    return nil
  end 

  action(table.unpack(item.action))

  if (not item.blockAutoDismiss and getMetaguiSetting("quickbarAutoDismiss", false)) or item.dismissQuickbar then
    pane.dismiss()
  end
end

function addQuickbarItem(item)
  local newListItem = "scroll.list." .. widget.addListItem("scroll.list")
  widget.setText(newListItem .. ".label", item.label)

  local container = newListItem .. ".buttonContainer"
  widget.registerMemberCallback(container, "click", function() itemCallback(item) end)
  
  local button = container .. "." .. widget.addListItem(container) .. ".button"
  widget.setButtonOverlayImage(button, item.icon or "/items/currency/essence.png")

  hoverTooltips["."..button] = string.format(" %s ", item.label)
end

function init()
  if dismissStardustQB() or dismissClassicQB() then
    return pane.dismiss()
  end
  
  buildList()
  
  local shared = getmetatable''
  shared.pat_classicqb_dismiss = pane.dismiss
  shared.pat_classicqb_rebuild = buildList
end

function uninit()
  widget.clearListItems("scroll.list")
  
  local shared = getmetatable''
  shared.pat_classicqb_dismiss = nil
  shared.pat_classicqb_rebuild = nil
end

function createTooltip(screenPosition)
  if not tooltipsEnabled then return end

  local childAt = widget.getChildAt(screenPosition)
  if not childAt then return end
  return hoverTooltips[childAt]
end
