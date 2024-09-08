local page = pat_classicQuickbar

require "/pat/classicquickbar/manager.lua"
require "/pat/classicquickbar/builder.lua"
require "/pat/classicquickbar/actions.lua"
actions._openStardustQuickbar = qbManager.openStardust

local function default(v, d)
  if v == nil then return d end
  return v
end

function page:init()
  self.settingsConfig = root.assetJson("/pat/classicquickbar/classicquickbar.json:settings")

  for k, s in pairs(self.config.strings) do
    self[k]:setText(s)
  end

  self.classicCheckbox:setChecked(default(metagui.settings.pat_classicEnabled, true))
  self.compactCheckbox:setChecked(default(metagui.settings.pat_compactQuickbar, false))
  self.leftCheckbox:setChecked(default(metagui.settings.pat_leftQuickbar, false))

  local itemList, hiddenItems = qbBuilder.getItems(self.filterItems)
  self.hiddenItems = hiddenItems

  for _, item in ipairs(itemList) do
    self:addListButton(item)
  end

  function page.compactCheckbox:onClick()
    page:setLeftModeLabel(self.checked)
  end
  self:setLeftModeLabel(self.compactCheckbox.checked)
end

function page:addListButton(item)
  local id = item.id

  local cfg = util.recReplaceTags(copy(page.config.menuItemTemplate), {id = id})
  local listButton = self.iconList:addChild(cfg)

  local label = self[id .. ".label"]
  local icon = self[id .. ".icon"]
  local hideIcon = self[id .. ".hidden"]

  local labelOff = string.format(self.settingsConfig.hideFormat, item.uncoloredLabel)
  local iconOff = string.format(self.settingsConfig.hideDirectives, item.icon)

  local function setHidden(hide)
    label:setText(hide and labelOff or item.label)
    icon:setFile(hide and iconOff or item.icon)
    icon:queueRedraw()
    hideIcon:setVisible(hide or false)
  end

  setHidden(item.hidden)

  function listButton:onClick()
    local hide = not item.hidden
    item.hidden = hide
    page.hiddenItems[id] = hide or nil
    setHidden(hide)

    apply.color = "accent"
  end

  if item.settingsButton then
    local b = self[id .. ".button"]
    b:setText(item.settingsButton.caption)
    b:setVisible(true)
    function b:onClick()
      action(table.unpack(item.settingsButton.action))
    end
  end
end

function page:save()
  local s = metagui.settings
  s.pat_hiddenIcons = self.hiddenItems
  s.pat_leftQuickbar = self.leftCheckbox.checked
  s.pat_compactQuickbar = self.compactCheckbox.checked

  local classic = self.classicCheckbox.checked
  if s.pat_classicEnabled ~= classic then
    s.pat_classicEnabled = classic
    metagui.startEvent(self.reopenQb)
  else
    metagui.startEvent(self.rebuildQbList)
  end

  apply.color = nil
end

function page:setLeftModeLabel(b)
  self.leftLabelOff:setVisible(b)
  self.leftLabel:setVisible(not b)
end

function page.filterItems(item)
  return not item.unhideable
end

function page.rebuildQbList()
  coroutine.yield()
  qbManager.rebuildClassic()
end

function page.reopenQb()
  coroutine.yield()
  if qbManager.dismiss() then
    coroutine.yield()
    qbManager.open()
  end
end
