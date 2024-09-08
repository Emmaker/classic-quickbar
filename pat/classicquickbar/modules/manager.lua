require "/pat/classicquickbar/modules/util.lua"
local mguiAvailable = qbUtil.isMetaguiAvailable
local shared = getmetatable''

local qbManager = {}
_ENV.qbManager = qbManager

function qbManager.open()
  if mguiAvailable() and not qbUtil.getMetaguiSetting("pat_classicEnabled", true) then
    return qbManager.openStardust()
  end
  return qbManager.openClassic()
end

function qbManager.dismiss()
  return qbManager.dismissClassic() or qbManager.dismissStardust()
end

local function getClassic()
  local cfg = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
  local bg = cfg.gui.background
  bg.fileBody = bg.fileBody_buttonless or bg.fileBody

  getClassic = function() return cfg end
  return cfg
end

function qbManager.openClassic()
  if qbManager.dismissClassic() then
    return
  end
  qbManager.dismissStardust()

  player.interact("ScriptPane", getClassic())
  return true
end

function qbManager.dismissClassic()
  return pcall(shared.pat_classicqb_dismiss)
end

function qbManager.rebuildClassic()
  return pcall(shared.pat_classicqb_rebuild)
end

function qbManager.openStardust()
  if not mguiAvailable() or qbManager.dismissStardust() then
    return
  end
  qbManager.dismissClassic()

  player.interact("ScriptPane", { gui = {}, scripts = { "/metagui.lua" }, config = "quickbar:quickbar" })
  return true
end

function qbManager.dismissStardust()
  if not mguiAvailable() then
    return
  end

  local ipc = shared.metagui_ipc
  if not ipc or not ipc.uniqueByPath then
    return
  end

  local path = root.assetJson("/metagui/registry.json:panes.quickbar.quickbar")
  return pcall(ipc.uniqueByPath[path])
end
