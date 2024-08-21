require "/pat/classicquickbar/shared.lua"

local mgui = metagui
local module = settings.module({ weight = 0 })

local function default(v, d)
  if v == nil then return d end
  return v
end

do
  local qbConfig = root.assetJson("/pat/classicquickbar/config.json")
  local strings = qbConfig.settings

  local page = module:page({
    title = strings.title,
    icon = "/pat/classicquickbar/stardustbar.png?border=1;000;0000",
    contents = {
      { type = "scrollArea", children = {
        {
          { type = "checkBox", id = "pat_classicEnabled", checked = default(mgui.settings.pat_classicEnabled, true) },
          { type = "label", text = strings.enableClassic, expand = true }
        },
        {
          { type = "checkBox", id = "pat_compactQuickbar", checked = default(mgui.settings.pat_compactQuickbar, false) },
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
    local iconConfig = root.assetJson("/quickbar/icons.json")
    local itemList = { }

    if iconConfig.items._stardustquickbar then
      iconConfig.items._stardustquickbar.weight = -math.huge
    end

    translateLegacyItems(iconConfig, qbConfig.legacyTranslation)

    self.hiddenIcons = getHiddenItems(iconConfig.items)
    
    --add items
    for k, item in pairs(iconConfig.items) do
      if not item.unhideable then
        item._id = k
        addItem(itemList, item, qbConfig.colorTags)
      end
    end
    
    sortItems(itemList)
    
    --create widgets
    for _, item in ipairs(itemList) do
      local id = item._id

      item.hidden = self.hiddenIcons[id] or false
      item.iconOff = item.icon.."?saturation=-50?brightness=-25"
      item.labelOff = "^lightgray;"..string.gsub(item.label, "(%b^;)", "")
      
      local listItem = page.iconList:addChild(
        { type = "menuItem", children = {
          { type = "image", id = id..".icon", size = {18, 18}, noAutoCrop = true },
          {
            {
              { type = "image", id = id..".hiddenIcon", file = "/pat/classicquickbar/hidden.png", visible = false },
              0,
              { type = "label", id = id..".label" }
            },
            { type = "label", id = id..".idlabel", text = id, color = "888" }
          }
        }}
      )
      
      if id == "_stardustquickbar" then
        listItem:addChild({ type = "button", id = "pat_openStardustQuickbar", caption = strings.openStardustQuickbar, inline = true, size = 48 })
        function page.pat_openStardustQuickbar:onClick()
          openStardustQB()
        end
      end

      local icon = page[id..".icon"]
      local label = page[id..".label"]
      local hiddenIcon = page[id..".hiddenIcon"]

      local function setHidden(hide)
        label:setText(hide and item.labelOff or item.label)
        icon:setFile(hide and item.iconOff or item.icon)
        icon:queueRedraw()
        hiddenIcon:setVisible(hide)
      end
      setHidden(item.hidden)
      
      --togglerer
      function listItem:onClick()
        item.hidden = not item.hidden
        setHidden(item.hidden)
        page.hiddenIcons[id] = item.hidden or nil
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
    local s = mgui.settings
    s.pat_hiddenIcons = self.hiddenIcons
    s.pat_compactQuickbar = page.pat_compactQuickbar.checked

    local classicCheck = page.pat_classicEnabled.checked
    if s.pat_classicEnabled ~= classicCheck then
      s.pat_classicEnabled = classicCheck
      metagui.startEvent(reopenQb)
    else
      metagui.startEvent(rebuildQbList)
    end

    apply.color = nil
  end

end
