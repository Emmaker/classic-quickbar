local shared = getmetatable''

function getMetaguiSetting(key, default)
  local settings = player.getProperty("metagui:settings", {})
  if settings[key] == nil then
    return default
  end
  return settings[key]
end

function dismissStardustQB()
  local ipc = shared.metagui_ipc
  if not ipc or not ipc.uniqueByPath then
    return
  end

  local mguiQuickbarPath = root.assetJson("/metagui/registry.json:panes.quickbar.quickbar")
  if ipc.uniqueByPath[mguiQuickbarPath] then
    ipc.uniqueByPath[mguiQuickbarPath]()
    return true
  end
end

function dismissClassicQB()
  if shared.pat_classicqb_dismiss then
    shared.pat_classicqb_dismiss()
    return true
  end
end

function openStardustQB()
  if dismissStardustQB() then
    return
  end
  dismissClassicQB()

  player.interact("ScriptPane", { gui = { }, scripts = { "/metagui.lua" }, config = "quickbar:quickbar" })
  return true
end

function openClassicQB()
  if dismissClassicQB() then
    return
  end
  dismissStardustQB()

  local qb = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
  local bg = qb.gui.background
  bg.fileBody = bg.fileBody_buttonless or bg.fileBody
  player.interact("ScriptPane", qb)

  return true
end

function openQuickbar()
  if getMetaguiSetting("pat_classicEnabled", true) then
    return openClassicQB()
  else
    return openStardustQB()
  end
end

function dismissQuickbar()
  return dismissClassicQB() or dismissStardustQB()
end
