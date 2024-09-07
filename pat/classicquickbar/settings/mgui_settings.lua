require "/pat/classicquickbar/util.lua"
require "/pat/classicquickbar/actions.lua"

actions._openStardustQuickbar = openStardustQB

local function default(v, d)
  if v == nil then return d end
  return v
end

local qbConfig = root.assetJson("/pat/classicquickbar/classicquickbar.json:settings")
local strings, images = qbConfig.strings, qbConfig.images

local module = settings.module({ weight = 0 })
local page = module:page({
  title = strings.title,
  icon = images.pageIcon,
  contents = {
    { type = "scrollArea", children = {
      {
        { type = "checkBox", id = "classicQbCheckbox", checked = default(metagui.settings.pat_classicEnabled, true) },
        { type = "label", text = strings.enableClassic, expand = true }
      },
      {
        { type = "checkBox", id = "leftQbCheckbox", checked = default(metagui.settings.pat_leftQuickbar, false) },
        { type = "label", text = strings.enableLeft, expand = true }
      },
      {
        { type = "checkBox", id = "compactQbCheckbox", checked = default(metagui.settings.pat_compactQuickbar, false) },
        { type = "label", text = strings.enableCompact, expand = true }
      },
      4,
      {
        4,
        { type = "label", text = strings.hideItems }
      },
      { type = "panel", style = "concave", expandMode = {1, 2}, children = {
        { type = "layout", id = "iconList", mode = "vertical", spacing = 1, children = {} }
      }},
      4,
      { type = "panel", style = "flat", expandMode = {1, 0}, children = {
        { type = "label", text = strings.scungus },
        { type = "image", file = images.scungus, scale = 0.25 }
      }}
    }}
  }
})

function page:init()
  local itemList, hiddenItems = getQuickbarItems(function(item)
    return not item.unhideable
  end)
  self.hiddenItems = hiddenItems

  --create widgets
  for _, item in ipairs(itemList) do
    local id = item.id
    
    local button = self.iconList:addChild(
      { type = "menuItem", children = {
        { type = "image", id = id..".icon", size = {18, 18}, noAutoCrop = true },
        {
          {
            { type = "image", id = id..".hidden", file = images.hiddenIcon, visible = false },
            0,
            { type = "label", id = id..".label" }
          },
          { type = "label", id = id..".idlabel", text = id, color = "888" }
        }
      }}
    )
    
    if item.settingsButton then
      local b = button:addChild({ type = "button", id = id..".button", caption = item.settingsButton.caption, inline = true, size = 48 })
      function b:onClick()
        action(table.unpack(item.settingsButton.action))
      end
    end

    local label = self[id..".label"]
    local icon = self[id..".icon"]
    local hideIcon = self[id..".hidden"]

    local labelOff = string.format(strings.hideFormat, item.uncoloredLabel)
    local iconOff = string.format(images.hideDirectives, item.icon)

    local function setHidden(hide)
      label:setText(hide and labelOff or item.label)
      icon:setFile(hide and iconOff or item.icon)
      icon:queueRedraw()
      hideIcon:setVisible(hide or false)
    end

    setHidden(item.hidden)

    function button:onClick()
      local hide = not item.hidden
      item.hidden = hide
      hiddenItems[id] = hide or nil
      setHidden(hide)

      apply.color = "accent"
    end
  end
end


local function rebuildQbList()
  coroutine.yield()
  rebuildClassicQB()
end

local function reopenQb()
  coroutine.yield()
  if dismissQuickbar() then
    coroutine.yield()
    openQuickbar()
  end
end

function page:save()
  local s = metagui.settings
  s.pat_hiddenIcons = self.hiddenItems
  s.pat_leftQuickbar = self.leftQbCheckbox.checked
  s.pat_compactQuickbar = self.compactQbCheckbox.checked

  local classicChecked = self.classicQbCheckbox.checked
  if s.pat_classicEnabled ~= classicChecked then
    s.pat_classicEnabled = classicChecked
    metagui.startEvent(reopenQb)
  else
    metagui.startEvent(rebuildQbList)
  end

  apply.color = nil
end
