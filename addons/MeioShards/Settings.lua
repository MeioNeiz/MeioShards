-- Options panel: Esc > Options > AddOns > MeioShards, or /shards settings. Writes straight
-- into MeioShardsDB, the same keys the chat commands set. Warlocks only.
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
  local category, layout = Settings.RegisterVerticalLayoutCategory("MeioShards")
  ns.SetCategory(category)
  Header(layout, "Deleting", "Extras go when you press the key (Esc > Options > Keybindings "
    .. "> AddOns), type /shards trim or click the count, or by themselves with Auto delete "
    .. "extras on. Never in combat.")
  Slider(category, "cap", "Keep at most", ns.CAP_MAX, "Above this many Soul Shards the count "
    .. "shows the cap in gold, and the extras are deleted: loose shards first, from your last "
    .. "bag slot. Nothing else is touched. Off: never delete. MeioPlates' Drain Soul cue "
    .. "follows this cap. /shards cap does the same.")
  Checkbox(category, "auto", "Auto delete extras", "New, off by default. Shards over your "
    .. "cap, or with no room in your soul bag, are deleted on your next key press or click in "
    .. "the world. Never in combat; in a dungeon they go after you leave. Never the shards you "
    .. "had at login or took from your bank, mail or a trade: press the key for those. "
    .. "/shards auto on||off does the same.")
  Checkbox(category, "overflow", "Loose shards", "With a soul bag "
    .. "equipped, the key deletes loose shards in your other bags once the soul bag is full, "
    .. "and moves them into it while it has room. Without a soul bag nothing is loose. "
    .. "/shards overflow on||off does the same.")

  Header(layout, "Running low", "Healthstone, Soulstone and every summon but the Imp cost "
    .. "one shard.")
  Slider(category, "warn", "Warn below", ns.WARN_MAX, "Fewer Soul Shards than this is low, "
    .. "once you know a spell that uses one: the count turns red. Off: never low. /shards warn "
    .. "does the same.")
  Checkbox(category, "chat", "Chat when low", "One line in chat when you run low. Never "
    .. "at login. /shards chat on||off does the same.")

  Header(layout, "Counter", "Your count also shows on Titan Panel, ChocolateBar and other data "
    .. "broker bars. /shards help lists every chat command.")
  Checkbox(category, "show", "Count on screen", "Off by default. Your Soul Shard count in "
    .. "a small box beside your bag buttons: hover it for what your shards can make, click it "
    .. "to delete the extras, Shift-drag to move it. /shards show on||off does the same.")
  if CreateSettingsButtonInitializer then
    layout:AddInitializer(CreateSettingsButtonInitializer("Counter position", "Reset position",
      function()
        ns.DB().point = nil
        ns.Place()
      end, "Put the counter back beside your bag buttons (same as /shards reset).", true))
  end
  Settings.RegisterAddOnCategory(category)
end
