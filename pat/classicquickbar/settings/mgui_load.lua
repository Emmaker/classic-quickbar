local cfg = root.assetJson("/pat/classicquickbar/settings/mgui_settings.config")
local module = settings.module(cfg.module)
local page = module:page(cfg.page)
page.config = cfg
_ENV.pat_classicQuickbar = page

for _, s in ipairs(cfg.scripts) do
  require(s)
end
