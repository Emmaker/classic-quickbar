function init()
  if not input or not input.bindDown then
    script.setUpdateDelta(0)
    return
  end

  require "/pat/classicquickbar/util.lua"
  local mgui = isMetaguiAvailable()

  function update(dt)
    if input.bindDown("pat_classicquickbar", "open") then
      openQuickbar()
    end

    if mgui and input.bindDown("pat_classicquickbar", "settings") then
      player.interact("ScriptPane", { gui = {}, scripts = { "/metagui.lua" }, config = "metagui:settings" })
    end
  end
end
