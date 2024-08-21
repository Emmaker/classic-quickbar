require "/pat/classicquickbar/shared.lua"
require "/pat/classicquickbar/actions.lua"

actions._openStardustQuickbar = openStardustQB

local function default(v, d)
  if v == nil then return d end
  return v
end

local strings = root.assetJson("/pat/classicquickbar/config.json:settings")

local module = settings.module({ weight = 0 })
local page = module:page({
  title = strings.title,
  icon = "/pat/classicquickbar/stardustbar.png?border=1;000;0000",
  contents = {
    { type = "scrollArea", children = {
      {
        { type = "checkBox", id = "pat_classicEnabled", checked = default(metagui.settings.pat_classicEnabled, true) },
        { type = "label", text = strings.enableClassic, expand = true }
      },
      {
        { type = "checkBox", id = "pat_compactQuickbar", checked = default(metagui.settings.pat_compactQuickbar, false) },
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
        { type = "image", file = "/pat/classicquickbar/scungus.png", scale = 0.25 }
      }}
    }}
  }
})

function page:init()
  local itemList, hiddenItems = getQuickbarItems(function(item, hidden)
    return not item.unhideable
  end)
  self.hiddenItems = hiddenItems

  --create widgets
  for _, item in ipairs(itemList) do
    local id = item._id
    
    local button = self.iconList:addChild(
      { type = "menuItem", children = {
        { type = "image", id = id..".icon", size = {18, 18}, noAutoCrop = true },
        {
          {
            { type = "image", id = id..".hidden", file = "/pat/classicquickbar/hidden.png", visible = false },
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

    local labelOff = "^lightgray;"..string.gsub(item.label, "(%b^;)", "")
    local iconOff = item.icon.."?saturation=-50?brightness=-25"

    local function setHidden(hide)
      label:setText(hide and labelOff or item.label)
      icon:setFile(hide and iconOff or item.icon)
      icon:queueRedraw()
      hideIcon:setVisible(hide or false)
    end

    setHidden(item._hidden)

    function button:onClick()
      local hide = not item._hidden
      item._hidden = hide
      hiddenItems[id] = hide or nil
      setHidden(hide)

      apply.color = "accent"
    end
  end
end


local function rebuildQbList()
  coroutine.yield()
  local shared = getmetatable''
  if shared.pat_classicqb_rebuild then
    shared.pat_classicqb_rebuild()
  end
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
  s.pat_compactQuickbar = self.pat_compactQuickbar.checked

  local classicCheck = self.pat_classicEnabled.checked
  if s.pat_classicEnabled ~= classicCheck then
    s.pat_classicEnabled = classicCheck
    metagui.startEvent(reopenQb)
  else
    metagui.startEvent(rebuildQbList)
  end

  apply.color = nil
end