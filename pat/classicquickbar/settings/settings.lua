require "/pat/classicquickbar/util.lua"

-- hide items with a "metaGuiAvailable" condition
require "/pat/classicquickbar/conditions.lua"
conditions = { ["not"] = conditions["not"], any = conditions.any, all = conditions.all }
conditions.metaguiAvailable = function() return false end
function condition(id, ...)
  if conditions[id] then return conditions[id](...) end
  return true
end

function init()
  self.settingsConfig = root.assetJson("/pat/classicquickbar/classicquickbar.json:settings")
  
  local compact = getMetaguiSetting("pat_compactQuickbar", false)
  widget.setChecked("autoDismiss", getMetaguiSetting("quickbarAutoDismiss", false))
  widget.setChecked("compactMode", compact)
  widget.setChecked("leftMode", getMetaguiSetting("pat_leftQuickbar", false))
  widget.setButtonEnabled("leftMode", not compact)
  
  self.itemList, self.hiddenItems = getQuickbarItems(function(item)
    return not item.unhideable and (not item.condition or condition(table.unpack(item.condition)))
  end)

  widget.registerMemberCallback("scrollArea.list", "click", toggleItem)
  for _, item in ipairs(self.itemList) do
    addListItem(item)
  end
end

function apply()
  widget.setButtonEnabled("apply", false)

  local settings = getMetaguiSetting()
  settings.quickbarAutoDismiss = widget.getChecked("autoDismiss")
  settings.pat_compactQuickbar = widget.getChecked("compactMode")
  settings.pat_leftQuickbar = widget.getChecked("leftMode")
  settings.pat_hiddenIcons = self.hiddenItems
  setMetaguiSetting(settings)
  rebuildClassicQB()
end

function enableApply() widget.setButtonEnabled("apply", true) end
function toggleAutoDismiss() enableApply() end
function toggleLeft() enableApply() end

function toggleCompact()
  enableApply()
  widget.setButtonEnabled("leftMode", not widget.getChecked("compactMode"))
end

function toggleItem(_, item)
  enableApply()
  local hidden = not self.hiddenItems[item.id] or nil
  self.hiddenItems[item.id] = hidden
  setItemHidden(item, hidden)
end

function addListItem(item)
  item.labelOff = string.format(self.settingsConfig.hideFormat, item.uncoloredLabel)
  item.iconOff = string.format(self.settingsConfig.hideDirectives, item.icon)
  
  item.listItem = "scrollArea.list." .. widget.addListItem("scrollArea.list")

  local hidden = self.hiddenItems[item.id] == true
  setItemHidden(item, hidden)
  widget.setData(item.listItem .. ".button", item)
  widget.setText(item.listItem .. ".id", item.id)
end

function setItemHidden(item, hidden)
  widget.setChecked(item.listItem .. ".button", hidden)
  widget.setText(item.listItem .. ".label", hidden and item.labelOff or item.label)
  widget.setImage(item.listItem .. ".icon", hidden and item.iconOff or item.icon)
  widget.setVisible(item.listItem .. ".hidden", hidden)
end
