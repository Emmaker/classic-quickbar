local mgui = metagui
local module = settings.module({ weight = 0 })

local function default(v, d)
  if v == nil then return d end
  return v
end

do
  local strings = root.assetJson("/metagui/pat_classicqb.json:settings")

  local page = module:page({
    title = strings.title,
    icon = "/sys/stardust/quickbar/pat_openstardust.png?border=1;000;0000",
    contents = {
      { type = "scrollArea", children = {
        {
          { type = "checkBox", id = "pat_compactQuickbar", checked = default(mgui.settings.pat_compactQuickbar, true) },
          { type = "label", text = strings.enableCompact, expand = true }
        },
        4,
        {
          4,
          { type = "label", text = strings.hideItems, inline = true, expand = true }
        },
        { type = "panel", style = "convex", expandMode = {1, 2}, children = {
          { type = "layout", id = "iconList", mode = "vertical", spacing = 1, children = {} }
        }},
        5,
        { type = "panel", style = "flat", expandMode = {1, 0}, children = {
          { type = "label", text = strings.scungus },
          { type = "image", file = "/metagui/scungus.png", scale = 0.25 }
        }}
      }}
    }
  })

  local hiddenIcons = mgui.settings.pat_hiddenIcons or {}

  function page:init()
    local iconConfig = root.assetJson("/quickbar/icons.json")
    local items = { }

    if iconConfig.openStardustQuickbar then
      iconConfig.items._stardustquickbar = iconConfig.openStardustQuickbar
      iconConfig.items._stardustquickbar.weight = -math.huge
    end

    --translate legacy entries
    for k, tr in pairs(iconConfig.legacyTranslation) do
      for _, item in ipairs(iconConfig[k]) do
        local id = string.format("_legacy.%s:%s", k, item.label)
        iconConfig.items[id] = {
          label = (tr.prefix or "")..item.label,
          icon = item.icon..(tr.directives or ""),
          weight = math.huge
        }
      end
    end
    
    --add items
    for k, item in pairs(iconConfig.items) do
      if not item.unhideable then
        local label = item.classicLabel or item.label
        item._id = k
        item._sort = string.lower(string.gsub(label, "(%b^;)", ""))
        item.label = string.gsub(label, "(%b^;)", iconConfig.colorTags)
        item.icon = item.icon or "/items/currency/essence.png"
        item.weight = item.weight or 0
        items[#items + 1] = item
      end
    end
    
    table.sort(items, function(a, b) return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort) end)
    
    --create widgets
    for _, item in ipairs(items) do
      local id = item._id
      local hide = hiddenIcons[id] or false
      
      local icon = item.icon
      local name = item.label
      local icon_off = icon.."?saturation=-50?brightness=-25"
      local name_off = "^#f00;[hidden]^reset; ^lightgray;"..string.gsub(name, "(%b^;)", "")
      
      local listItem = page.iconList:addChild(
        { type = "menuItem", children = {
          { type = "image", id = id..".image", size = {18, 18}, noAutoCrop = true, file = hide and icon_off or icon },
          {
            { type = "label", id = id..".label", text = hide and name_off or name },
            { type = "label", id = id..".idlabel", text = id, color = "888" }
          }
        }}
      )
      
      local image = page[id..".image"]
      local label = page[id..".label"]
      
      --togglerer
      function listItem:onClick()
        hide = not hide
        hiddenIcons[id] = hide or nil
        
        label:setText(hide and name_off or name)
        image:setFile(hide and icon_off or icon)
        image:queueRedraw()
        
        apply.color = "accent"
      end
    end
  end

  function page:save()
    mgui.settings.pat_compactQuickbar = page.pat_compactQuickbar.checked
    mgui.settings.pat_hiddenIcons = hiddenIcons
    
    apply.color = nil
    
    local shared = getmetatable''
    if shared.pat_classicqb_rebuild then
      metagui.startEvent(function()
        util.wait(0.02)
        shared.pat_classicqb_rebuild()
      end)
    end
  end

end
