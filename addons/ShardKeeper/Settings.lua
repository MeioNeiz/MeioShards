-- Options panel: Esc > Options > AddOns > ShardKeeper, or /shards settings. Writes straight
-- into ShardKeeperDB, the same keys the chat commands set. Warlocks only.
local _, ns = ...

ns.CAP_MAX, ns.WARN_MAX = 40, 10

local function Header(layout, title, tip)
  if layout and CreateSettingsListSectionHeaderInitializer then
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(title, tip))
  end
end

local function Register(category, key, kind, name)
  local setting = Settings.RegisterAddOnSetting(category, "SHARDKEEPER_" .. key:upper(), key,
    ns.DB(), kind, name, ns.DEFAULTS[key])
  setting:SetValueChangedCallback(function() ns.Update() end)
  ns.settings[key] = setting
  return setting
end

local function Slider(category, key, name, max, tip)
  local setting = Register(category, key, Settings.VarType.Number, name)
  local options = Settings.CreateSliderOptions(0, max, 1)
  if MinimalSliderWithSteppersMixin then
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
      function(v) return v == 0 and "Off" or tostring(v) end)
  end
  Settings.CreateSlider(category, setting, options, tip)
end

local function Checkbox(category, key, name, tip)
  Settings.CreateCheckbox(category, Register(category, key, Settings.VarType.Boolean, name), tip)
end

function ns.RegisterSettings()
  if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
  local category, layout = Settings.RegisterVerticalLayoutCategory("ShardKeeper")
  ns.SetCategory(category)
  Checkbox(category, "show", "Shard counter", "Your Soul Shard count in a small box beside "
    .. "your bag buttons. Shift-drag it to move it; hover it for what your shards can make. "
    .. "/shards show on||off does the same.")

  Header(layout, "Deleting", "Shards are only ever deleted when you click the counter, press "
    .. "the key (Esc > Options > Keybindings > AddOns) or type /shards trim.")
  Checkbox(category, "overflow", "Delete loose shards", "With a soul bag "
    .. "equipped, the key deletes loose shards in your other bags once the soul bag is full, "
    .. "and moves them into it while it has room. Without a soul bag nothing is loose. "
    .. "/shards overflow on||off does the same.")
  Slider(category, "cap", "Keep at most", ns.CAP_MAX, "Above this many Soul Shards the counter "
    .. "shows the cap in gold, and a click on it deletes the extras: loose shards first, from "
    .. "your last bag slot. Nothing else is touched. Off: never delete. MeioPlates' Drain Soul "
    .. "cue follows this cap. /shards cap does the same.")

  Header(layout, "Running low", "Healthstone, Soulstone and every summon but the Imp cost "
    .. "one shard.")
  Slider(category, "warn", "Warn below", ns.WARN_MAX, "The counter turns red with fewer Soul "
    .. "Shards than this, once you know a spell that uses one. Off: never red. /shards warn "
    .. "does the same.")
  Checkbox(category, "chat", "Chat line when low", "One line in chat when the counter turns "
    .. "red. Never at login. /shards chat on||off does the same.")

  if CreateSettingsButtonInitializer then
    Header(layout, "Counter", "/shards help lists every chat command.")
    layout:AddInitializer(CreateSettingsButtonInitializer("Counter position", "Reset position",
      function()
        ns.DB().point = nil
        ns.Place()
      end, "Put the counter back beside your bag buttons (same as /shards reset).", true))
  end
  Settings.RegisterAddOnCategory(category)
end
