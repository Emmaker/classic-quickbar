function init()
  if not input or not input.bindDown then
    script.setUpdateDelta(0)
    return
  end

  require "/pat/classicquickbar/shared.lua"

  function update(dt)
    if input.bindDown("pat_classicquickbar", "open") then
      openClassicQB()
    end
  end
end
