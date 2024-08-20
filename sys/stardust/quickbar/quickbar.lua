require "/sys/quickbar/conditions.lua"
require "/sys/stardust/quickbar/actions.lua"

local hoverTooltips = { }
local tooltipsEnabled = false

local function getMetaguiSetting(key, default)
  local settings = player.getProperty("metagui:settings", {})
  if settings[key] == nil then
    return default
  end
  return settings[key]
end

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

  if iconConfig.openStardustQuickbar then
    iconConfig.items._stardustquickbar = iconConfig.openStardustQuickbar
  end

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
  local shared = getmetatable''

  -- close stardust quickbar
  local ipc = shared.metagui_ipc
  if ipc and ipc.uniqueByPath and not config.getParameter("mgipc_noDismiss") then
    local path = root.assetJson("/metagui/registry.json:panes.quickbar.quickbar")
    if ipc.uniqueByPath[path] then
      ipc.uniqueByPath[path]()
      return pane.dismiss()
    end
  end
  
  if shared.pat_classicqb_dismiss then
    shared.pat_classicqb_dismiss()
    return pane.dismiss()
  end
  
  shared.pat_classicqb_dismiss = pane.dismiss
  shared.pat_classicqb_rebuild = buildList
  
  buildList()
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
