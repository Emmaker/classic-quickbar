require "/pat/classicquickbar/util.lua"

local shared = getmetatable''

function init()
  self.metaguiAvailable = isMetaguiAvailable()

  loadConditionsAndActions()
  require "/pat/classicquickbar/conditions.lua"
  require "/pat/classicquickbar/actions.lua"
  qbActions = actions -- alias for compatibility

  conditions.classicQuickbar = function() return true end
  conditions.metaguiAvailable = function() return self.metaguiAvailable end
  
  if dismissClassicQB() or dismissStardustQB()
  or (self.metaguiAvailable and not getMetaguiSetting("pat_classicEnabled", true) and openStardustQB()) then
    return pane.dismiss()
  end

  self.hoverTooltips = {}
  self.tooltipsEnabled = false
  
  buildList()
  
  shared.pat_classicqb_dismiss = pane.dismiss
  shared.pat_classicqb_rebuild = buildList
end

function uninit()
  widget.clearListItems("scroll.list")
  shared.pat_classicqb_dismiss = nil
  shared.pat_classicqb_rebuild = nil
end

function buildList()
  local listWidgets = config.getParameter("listWidgets")
  local listConfig = listWidgets[getListMode()]
  widget.removeChild("scroll", "list")
  widget.addChild("scroll", listConfig, "list")

  self.tooltipsEnabled = listConfig.tooltips
  self.hoverTooltips = {}

  local itemList = getQuickbarItems(filterItems)
  
  for _, item in ipairs(itemList) do
    addQuickbarButton(item)
  end
end

function getListMode()
  local settings = getMetaguiSetting()

  if settings.pat_compactQuickbar then
    return "compact"
  elseif settings.pat_leftQuickbar then
    return "left"
  end
  
  return "default"
end

function filterItems(item)
  if item.hidden and not item.unhideable then
    return false
  end

  if item.condition then
    return condition(table.unpack(item.condition))
  end

  return true
end

function addQuickbarButton(item)
  local newListItem = "scroll.list." .. widget.addListItem("scroll.list")
  widget.setText(newListItem .. ".label", item.label)

  local container = newListItem .. ".buttonContainer"
  widget.registerMemberCallback(container, "click", buttonCallback(item))
  
  local button = container .. "." .. widget.addListItem(container) .. ".button"
  widget.setButtonOverlayImage(button, item.icon)

  if item.buttonImages then
    widget.setButtonImages(button, item.buttonImages)
  end

  self.hoverTooltips["." .. button] = string.format(" %s ", item.label)
end

function buttonCallback(item)
  return function()
    if item.condition and not condition(table.unpack(item.condition)) then -- recheck condition on attempt
      pane.playSound("/sfx/interface/nav_insufficient_fuel.ogg")
      buildList()
      return
    end 

    action(table.unpack(item.action))

    if item.dismissQuickbar or (not item.blockAutoDismiss and getMetaguiSetting("quickbarAutoDismiss", false)) then
      pane.dismiss()
    end
  end
end

function createTooltip(screenPosition)
  if not self.tooltipsEnabled then return end
  local childAt = widget.getChildAt(screenPosition)
  if not childAt then return end
  return self.hoverTooltips[childAt]
end

function loadConditionsAndActions()
  -- Stardust conditions
  if self.metaguiAvailable then
    pcall(require, "/sys/quickbar/conditions.lua")
  end

  -- Community Framework conditions & actions
  if root.assetJson("/player.config:genericScriptContexts").cf_codex ~= nil then
    pcall(require, "/quickbar/conditions.lua")
    pcall(require, "/quickbar/actions.lua")
  end
end
