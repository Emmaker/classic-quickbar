require "/pat/classicquickbar/util.lua"
require "/pat/classicquickbar/actions.lua"
require "/sys/quickbar/conditions.lua"
conditions.pat_classicQuickbar = function() return true end

local hoverTooltips = { }
local tooltipsEnabled = false

local function buildList()
  local compact = getMetaguiSetting("pat_compactQuickbar", false)
  local listWidgets = config.getParameter("listWidgets")
  local listConfig = listWidgets[compact and "compact" or "default"]
  widget.removeChild("scroll", "list")
  widget.addChild("scroll", listConfig, "list")

  tooltipsEnabled = listConfig.tooltips
  hoverTooltips = { }

  local itemList = getQuickbarItems(function(item, hidden)
    if not item.unhideable and hidden then
      return false
    end
    return not item.condition or condition(table.unpack(item.condition))
  end)
  
  for _, item in ipairs(itemList) do
    addQuickbarButton(item)
  end
end

local function buttonCallback(item)
  if item.condition and not condition(table.unpack(item.condition)) then -- recheck condition on attempt
    pane.playSound("/sfx/interface/clickon_error.ogg")
    return nil
  end 

  action(table.unpack(item.action))

  if (not item.blockAutoDismiss and getMetaguiSetting("quickbarAutoDismiss", false)) or item.dismissQuickbar then
    pane.dismiss()
  end
end

function addQuickbarButton(item)
  local newListItem = "scroll.list." .. widget.addListItem("scroll.list")
  widget.setText(newListItem .. ".label", item.label)

  local container = newListItem .. ".buttonContainer"
  widget.registerMemberCallback(container, "click", function() buttonCallback(item) end)
  
  local button = container .. "." .. widget.addListItem(container) .. ".button"
  widget.setButtonOverlayImage(button, item.icon)

  if item.buttonImages then
    widget.setButtonImages(button, item.buttonImages)
  end

  hoverTooltips["." .. button] = string.format(" %s ", item.label)
end

function init()
  if not getMetaguiSetting("pat_classicEnabled", true) and openStardustQB() then
    return pane.dismiss()
  end

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
