local mg = metagui
local m = settings.module { weight = 0 }

local function default(v, d)
  if v == nil then return d end
  return v
end

do
  local p = m:page({
    title = "Classic Quickbar",
    icon = "/sys/stardust/quickbar/pat_openstardust.png?border=1;000;0000",
    contents = {
      {
        { type = "checkBox", id = "pat_hideSettings", checked = default(mg.settings.pat_hideSettings, false) },
        { type = "label", text = "Hide settings icon in Classic Quickbar" }
      },
      75,
      {
        { type = "panel", style = "convex", children = {
          { type = "label", text = "this is scungus :)      he HATES metagui" },
          { type = "image", file = "/metagui/scungus.png", scale = 0.75 }
        }}
      }
    }
  })
  
  function p:save()
    mg.settings.pat_hideSettings = p.pat_hideSettings.checked
  end
end