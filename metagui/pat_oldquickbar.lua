local mg = metagui
local m = settings.module { weight = 0 }

local function default(v, d)
  if v == nil then return d end
  return v
end

local colorSub = {
  ["^essential;"] = "^#ffb133;",
  ["^admin;"] = "^#bf7fff;",
}

do
  local p = m:page({
    title = "Classic Quickbar",
    icon = "/sys/stardust/quickbar/pat_openstardust.png?border=1;000;0000",
    contents = {
      { type = "label", text = "Hidden Classic Quickbar Icons", inline = true },
      { type = "panel", style = "convex", expandMode = {1, 2}, children = {
        { type = "scrollArea", id = "iconList", children = { { spacing = 1 } } }
      }}
    }
  })
  
  local Hidden = mg.settings.pat_hiddenIcons or {}
  if mg.settings.pat_hideSettings then
    Hidden["metagui:settings"] = true
    mg.settings.pat_hideSettings = nil
  end
  
  function p:init()
    local c = root.assetJson("/quickbar/icons.json")
    local items = { }
    
    --translate legacy items
    for _,i in ipairs(c.priority) do
      c.items["_legacy.priority:"..i.label] = {label = "^essential;"..i.label, icon = i.icon, weight = math.huge}
    end
    for _,i in ipairs(c.admin) do
      c.items["_legacy.admin:"..i.label] = {label = "^admin;"..i.label, icon = i.icon, weight = math.huge}
    end
    for _,i in ipairs(c.normal) do
      c.items["_legacy.normal:"..i.label] = {label = i.label, icon = i.icon, weight = math.huge}
    end
    
    --add items
    for k,i in pairs(c.items) do
      i._id = k
      i._sort = string.lower(string.gsub(i.label, "(%b^;)", ""))
      i.label = string.gsub(i.label, "(%b^;)", colorSub)
      i.icon = i.icon or "/items/currency/essence.png"
      i.weight = i.weight or 0
      items[#items+1] = i
    end
    
    table.sort(items, function(a, b) return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort) end)
    
    --create widgets
    for _,i in ipairs(items) do
      local id = i._id
      local hide = Hidden[id] or false
      
      local icon = i.icon
      local name = i.label
      local icon_off = icon.."?saturation=-50?brightness=-25"
      local name_off = "^#f00;[hidden]^reset; "..string.gsub(name, "(%b^;)", "^lightgray;")
      
      local w = p.iconList:addChild(
        {type = "menuItem", children = {
          { type = "image", id = id..".image", size = {18, 18}, noAutoCrop = true, file = hide and icon_off or icon},
          4,
          {
            { type = "label", id = id..".label", text = hide and name_off or name },
            { type = "label", text = id, color = "888" }
          }
        }}
      )
      local image = p[id..".image"]
      local label = p[id..".label"]
      
      --togglerer
      w.onClick = function()
        hide = not hide
        Hidden[id] = hide or nil
        
        label:setText(hide and name_off or name)
        image:setFile(hide and icon_off or icon)
        image:queueRedraw()
      end
    end
    
    p.iconList:addChild({ type = "panel", style = "flat", children = {
      { type = "label", text = "this is scungus :)      he HATES metagui" },
      { type = "image", file = "/metagui/scungus.png", scale = 0.25 }
    }})
  end
  
  function p:save()
    mg.settings.pat_hiddenIcons = Hidden
    local m = getmetatable''
    
    if m.pat_classicqb_rebuild then
      metagui.startEvent(function()
        util.wait(0.02)
        m.pat_classicqb_rebuild()
      end)
    end
  end
end