-- Soul Shards for warlocks: a cap, deleting the extras and the loose shards a full soul bag
-- has no room for, a warning when low, the count on data broker bars and an on-screen
-- counter (off by default). With no shard to delete, the key falls
-- through to the cheapest junk item (MeioBags, else RestedXP's delete-cheapest-junk).
-- Shards are plain bag items: no secret values. DeleteCursorItem needs a hardware event, so
-- Trim runs only from a click on the counter or broker feed, the key binding or /shards trim, and the auto
-- trim from any key press or click in the world (Warlock Tools Forever's method); never from
-- an event or timer. The client refuses addon deletes in combat and under some restrictions
-- (ADDON_ACTION_BLOCKED, a BugSack error), so both check first.
-- Read-only API for other addons (MeioPlates' Drain Soul cue), no hooks needed:
--   MeioShards.Count() -> shards in bags; MeioShards.Cap() -> cap or nil when off;
--   MeioShards.WantsMore() -> true while below the cap (always, with no cap)
local ADDON, ns = ...
local SLASH = "/shards"
local SHARD = 6265
-- bag family bit of a Soul Pouch / Felcloth Bag
local SOUL_FAMILY = 0x4
local PREFIX = "|cffb090ffMeioShards:|r "
local GOLD, MUTED, GOOD, BAD = "|cffffd100", "|cff999999", "|cff80ff80", "|cffff8080"
local SETTINGS_PATH = "Esc > Options > AddOns > MeioShards"
local KEY_PATH = "Esc > Options > Keybindings > AddOns"
local DEFAULTS = { show = false, cap = 20, warn = 1, chat = true, overflow = true, auto = false }
-- 2: counter off by default (1.4.0); hidden once for those who had it, the chat line taking
-- over its red low warning
local DB_VERSION = 2
-- out of the way by default (never mid-screen): beside the bag buttons, shards being bag
-- items; top-left corner when there is no bags bar
local FALLBACK_POINT = { "TOPLEFT", "TOPLEFT", 6, -80 }
local BAGS_GAP = 6
local FLARE_BORDER = "Interface\\AddOns\\FlareUI\\Media\\Borders\\FlareUI-Thin.tga"
local BRONZE = { 0.65, 0.49, 0.27 }
local GREY = { 0.5, 0.5, 0.5 }
local RED = { 0.9, 0.25, 0.22 }
local DRAG_CLICK_GUARD = 0.3
-- shards that arrive while one of these is open (or just after: BAG_UPDATE_DELAYED lags the
-- close) were brought, not farmed, and auto trim keeps them
local SOURCES = {
  BANKFRAME_OPENED = "BANKFRAME_CLOSED", MAIL_SHOW = "MAIL_CLOSED",
  TRADE_SHOW = "TRADE_CLOSED", GUILDBANKFRAME_OPENED = "GUILDBANKFRAME_CLOSED",
}
local SOURCE_GRACE = 2
-- the key or click that just auto trimmed shouldn't then say "nothing to delete"
local AUTO_ECHO = 0.5
local HARD_RESTRICTIONS = { "Combat", "Encounter", "ChallengeMode", "PvPMatch" }
local MAP_LINE = "the game doesn't let addons delete items in this dungeon: delete by hand, "
  .. "or the extras go after you leave"

-- What a shard buys, highest rank first. short: in the default tooltip line; items: the made
-- item, to say you already carry one. perCast: costs a shard every cast.
local USES = {
  { label = "Healthstone", short = true, spells = { 11730, 11729, 5699, 6202, 6201 },
    items = { 5512, 5511, 5509, 5510, 9421, 19004, 19005, 19006, 19007, 19008, 19009, 19010,
      19011, 19012, 19013 } },
  { label = "Soulstone", short = true, spells = { 20757, 20756, 20755, 20752, 693 },
    items = { 16896, 16895, 16893, 16892, 5232 } },
  { label = "Spellstone", spells = { 17728, 17727, 2362 }, items = { 13603, 13602, 5522 } },
  { label = "Firestone", spells = { 17953, 17952, 17951, 6366 },
    items = { 13701, 13700, 13699, 1254 } },
  { label = "Voidwalker", short = true, spells = { 697 } },
  { label = "Succubus", short = true, spells = { 712 } },
  { label = "Felhunter", short = true, spells = { 691 } },
  { label = "Ritual of Summoning", short = true, spells = { 698 } },
  { label = "Soul Fire", perCast = true, spells = { 17924, 6353 } },
  { label = "Shadowburn", perCast = true, spells = { 18871, 18870, 18869, 18868, 18867, 17877 } },
}

local db, isWarlock, category
local settings = {}
local count, perBag, overflow = 0, {}, 0
-- shards auto trim never deletes: those at login and those brought from a bank, mail or trade;
-- lowered as shards are used
local keep
local sourcing, sourceUntil = {}, 0
local mapRefused, lastAuto = false, 0
-- after an auto delete, until the bags rescan: a second key press would see the old count
local autoWait = false
local wasLow, scanned
-- login is silent: spells and bags arrive in pieces just after it
local QUIET_AFTER_LOGIN = 10
local loginAt = 0
local known = {}

local function Print(text) print(PREFIX .. text) end
local function Line(text) print("  " .. text) end
local function Cmd(text) return GOLD .. text .. "|r" end
local function OnOff(on) return on and GOOD .. "on|r" or BAD .. "off|r" end

local function Cap() return db and db.cap and db.cap > 0 and db.cap or nil end
local function AboveCap() local cap = Cap() return cap and math.max(0, count - cap) or 0 end
local function Extra() return math.max(AboveCap(), overflow) end

local function Restricted(name)
  local kinds = Enum and Enum.AddOnRestrictionType
  local api = C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive
  if not (api and kinds and kinds[name]) then return false end
  return api(kinds[name]) == true
end

local function InCombat()
  if InCombatLockdown() then return true end
  local fighting = UnitAffectingCombat("player")
  if (issecretvalue and issecretvalue(fighting)) or fighting then return true end
  for _, name in ipairs(HARD_RESTRICTIONS) do
    if Restricted(name) then return true end
  end
  return false
end

-- set for a whole dungeon visit; may still allow deletes, so only a click tries
local function MapRestricted() return Restricted("Map") end

local function Sourcing() return next(sourcing) ~= nil or GetTime() < sourceUntil end

local function AutoExtra()
  if not (db and db.auto and keep) then return 0 end
  return math.min(Extra(), math.max(0, count - keep))
end

local function LastBag() return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 end

local function BagFamily(bag)
  if not C_Container.GetContainerNumFreeSlots then return 0 end
  local _, family = C_Container.GetContainerNumFreeSlots(bag)
  return family or 0
end

local function IsSoulBag(bag) return bit.band(BagFamily(bag), SOUL_FAMILY) ~= 0 end

local function BagName(bag)
  local name = C_Container.GetBagName and C_Container.GetBagName(bag)
  if name and name ~= "" then return name end
  if bag == 0 then return BACKPACK_TOOLTIP or "Backpack" end
  return "Bag " .. bag
end

-- -> total shards, per-bag counts, loose shards the soul bag has no room for (0 without one
-- or with the option off: then nothing is loose, every bag is the shard bag)
local function Scan()
  local total, per = 0, {}
  local loose, free, hasSoulBag = 0, 0, false
  for bag = 0, LastBag() do
    local n = 0
    local soul = IsSoulBag(bag)
    if soul then
      hasSoulBag = true
      free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0)
    end
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == SHARD then n = n + (info.stackCount or 1) end
    end
    if n > 0 then per[#per + 1] = { bag = bag, count = n } end
    if not soul then loose = loose + n end
    total = total + n
  end
  local over = (hasSoulBag and db and db.overflow) and math.max(0, loose - free) or 0
  return total, per, over
end

local function SpellKnown(id)
  return C_SpellBook.IsSpellKnown(id)
end

-- use -> highest known rank's spell ID
local function LearnSpells()
  wipe(known)
  for _, use in ipairs(USES) do
    for _, id in ipairs(use.spells) do
      if SpellKnown(id) then known[use] = id break end
    end
  end
end

local function KnowsAny() return next(known) ~= nil end

local function Needed() return KnowsAny() and (db.warn or 0) or 0 end

local function Carries(use)
  for _, id in ipairs(use.items or {}) do
    if C_Item.GetItemCount(id) > 0 then return true end
  end
end

------------------------------------------------------------------------------ counter frame
local frame = CreateFrame("Button", "MeioShardsFrame", UIParent, "BackdropTemplate")
frame:SetSize(56, 26)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:RegisterForClicks("LeftButtonUp")
frame:Hide()

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(18, 18)
icon:SetPoint("LEFT", 5, 0)
icon:SetTexture(C_Item.GetItemIconByID(SHARD) or "Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.Count = text
text:SetPoint("LEFT", icon, "RIGHT", 5, 0)

local borderColour = BRONZE

-- FlareUI's thin bronze edge when it is loaded, so the counter reads as one of its bars
local function Style()
  local flare = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("FlareUI")
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = flare and FLARE_BORDER or "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = flare and 8 or 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  frame:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
  borderColour = flare and BRONZE or GREY
end

-- Below the bags bar when it sits in the top half (Edit Mode moved it up), else to its left
-- (Blizzard's bottom-right default). Anchored to the bar itself so it follows Edit Mode.
local function PlaceByBags()
  local bags = BagsBar
  if not (bags and bags:IsShown() and bags:GetCenter()) then return false end
  local _, y = bags:GetCenter()
  local screenY = y * bags:GetEffectiveScale() / UIParent:GetEffectiveScale()
  if screenY > UIParent:GetHeight() / 2 then
    frame:SetPoint("TOPLEFT", bags, "BOTTOMLEFT", 0, -BAGS_GAP)
  else
    frame:SetPoint("RIGHT", bags, "LEFT", -BAGS_GAP, 0)
  end
  return true
end

local function Place()
  frame:ClearAllPoints()
  local p = db.point
  if not p and PlaceByBags() then return end
  p = p or FALLBACK_POINT
  ---@diagnostic disable-next-line: param-type-mismatch
  frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

local function ShowTooltip() end
-- the counter, or a data broker display's button (Titan Panel, ChocolateBar)
local tipOwner = frame
local broker
local function TooltipOpen() return GameTooltip:IsShown() and GameTooltip:IsOwned(tipOwner) end

local function Update()
  if not (db and isWarlock) then return end
  count, perBag, overflow = Scan()
  autoWait = false
  local quiet = GetTime() - loginAt < QUIET_AFTER_LOGIN
  -- bags fill in over the first seconds: all of that is "at login"
  if not keep or count < keep or (count > keep and (quiet or Sourcing())) then keep = count end
  local low = count < Needed()
  local cap = Cap()
  if low then
    text:SetText(BAD .. count .. "|r")
  elseif cap and count > cap then
    text:SetText(count .. GOLD .. "/" .. cap .. "|r")
  elseif overflow > 0 then
    text:SetText(GOLD .. count .. "|r")
  else
    text:SetText(tostring(count))
  end
  local c = low and RED or borderColour
  frame:SetBackdropBorderColor(c[1], c[2], c[3], 1)
  frame:SetWidth(math.ceil(text:GetStringWidth()) + 18 + 5 + 5 + 8)
  frame:SetShown(db.show and (count > 0 or KnowsAny()))
  if broker then broker.text = text:GetText() end
  if scanned and low and not wasLow and db.chat and not quiet then
    Print(BAD .. (count == 0 and "no Soul Shards left" or ("only %d Soul Shard%s left")
      :format(count, count == 1 and "" or "s")) .. "|r: Drain Soul a mob as it dies for more")
  end
  wasLow, scanned = low, true
  if TooltipOpen() then ShowTooltip(tipOwner) end
end

local function TrimOrder()
  local general, special = {}, {}
  for bag = LastBag(), 0, -1 do
    local list = BagFamily(bag) == 0 and general or special
    for slot = C_Container.GetContainerNumSlots(bag), 1, -1 do
      if C_Container.GetContainerItemID(bag, slot) == SHARD then
        list[#list + 1] = { bag = bag, slot = slot }
      end
    end
  end
  -- loose shards first: they take general bag space, a Soul Pouch's don't
  for _, s in ipairs(special) do general[#general + 1] = s end
  return general
end

local function Plural(n) return n == 1 and "" or "s" end

-- loose shards into the soul bag's empty slots; -> how many moved
local function Tidy()
  local free = {}
  for bag = 0, LastBag() do
    if IsSoulBag(bag) then
      for slot = 1, C_Container.GetContainerNumSlots(bag) do
        if not C_Container.GetContainerItemID(bag, slot) then
          free[#free + 1] = { bag = bag, slot = slot }
        end
      end
    end
  end
  local moved = 0
  for bag = 0, LastBag() do
    if BagFamily(bag) == 0 then
      for slot = 1, C_Container.GetContainerNumSlots(bag) do
        if moved >= #free then return moved end
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID == SHARD and not info.isLocked then
          C_Container.PickupContainerItem(bag, slot)
          local kind, id = GetCursorInfo()
          if kind ~= "item" or id ~= SHARD then
            ClearCursor()
            return moved
          end
          local to = free[moved + 1]
          C_Container.PickupContainerItem(to.bag, to.slot)
          if CursorHasItem() then
            ClearCursor()
            return moved
          end
          moved = moved + 1
        end
      end
    end
  end
  return moved
end

-- -> shards deleted, true when the client refused a delete
local function Delete(excess)
  local deleted = 0
  for _, s in ipairs(TrimOrder()) do
    if deleted >= excess then break end
    local info = C_Container.GetContainerItemInfo(s.bag, s.slot)
    local n = info and info.stackCount or 1
    if info and info.itemID == SHARD and not info.isLocked and n <= excess - deleted then
      C_Container.PickupContainerItem(s.bag, s.slot)
      local kind, id = GetCursorInfo()
      if kind ~= "item" or id ~= SHARD then
        ClearCursor()
        break
      end
      DeleteCursorItem()
      -- refused: put it back rather than drop it in the next slot
      if CursorHasItem() then
        ClearCursor()
        return deleted, true
      end
      deleted = deleted + n
    end
  end
  return deleted, false
end

-- deletes the loose shards a full soul bag has no room for and any above the cap, then
-- moves the loose ones that fit into the soul bag. False when there was nothing to do
-- (quiet, as from a macro: say nothing then, nor in combat)
local function Trim(quiet)
  if not (db and isWarlock) then return false end
  if InCombat() then
    if quiet then return false end
    Print(BAD .. "not in combat|r" .. (db.auto and AutoExtra() > 0
      and ": the extras go by themselves after the fight" or ": click again after the fight"))
    return true
  end
  if CursorHasItem() then
    Print(BAD .. "put down the item on your cursor first|r")
    return true
  end
  count, perBag, overflow = Scan()
  local excess = Extra()
  local map = MapRestricted()
  if excess > 0 and map and mapRefused then
    Print(MAP_LINE)
    return true
  end
  local deleted, refused = Delete(excess)
  if refused and deleted == 0 and map then
    mapRefused = true
    Print(MAP_LINE)
    return true
  end
  if keep then keep = math.min(keep, count - deleted) end
  local moved = db.overflow and Tidy() or 0
  if excess > 0 and deleted == 0 then
    Print(BAD .. "could not delete any Soul Shards|r (try again in a moment)")
  elseif deleted > 0 then
    Print(("deleted %d Soul Shard%s, kept %d"):format(deleted, Plural(deleted), count - deleted)
      .. (moved > 0 and (", moved %d into your soul bag"):format(moved) or ""))
  elseif moved > 0 then
    Print(("moved %d Soul Shard%s into your soul bag"):format(moved, Plural(moved)))
  else
    if quiet or GetTime() - lastAuto < AUTO_ECHO then return false end
    local cap = Cap()
    Print(("%d Soul Shards, nothing to delete"):format(count)
      .. (cap and (" (cap %d)"):format(cap) or ""))
    return false
  end
  return true
end

-- Once no shard needs deleting the key deletes the cheapest junk item instead: one key for
-- both. MeioBags when loaded, else RestedXP's "Delete Cheapest Junk Item" button (a plain
-- Button, not secure). One action per press, so a press never costs a shard and junk at once.
local function JunkDelete()
  local mb = _G.MeioBags
  if type(mb) == "table" and mb.DeleteJunk then return mb.DeleteJunk end
  local b = _G.RXPInventory_DeleteJunk
  if type(b) == "table" and b.Click then return function() b:Click() end end
end

local function Key()
  local junk = JunkDelete()
  if Trim(junk ~= nil) or not junk then return end
  junk()
end

-- silent: the counter going down is the feedback; one chat line per Drain Soul kill at the
-- cap would be noise. Never in a dungeon (a refusal is a BugSack error); they go on leaving.
local function AutoTrim()
  if not isWarlock or autoWait or AutoExtra() == 0 then return end
  if InCombat() or MapRestricted() or CursorHasItem() then return end
  if Delete(AutoExtra()) > 0 then
    lastAuto, autoWait = GetTime(), true
  end
end

WorldFrame:HookScript("OnMouseDown", AutoTrim)

-- sees every key press without taking it from the game; propagation is protected in combat
local keys = CreateFrame("Frame", nil, UIParent)
keys:EnableKeyboard(true)
keys:SetScript("OnKeyDown", AutoTrim)
local function Propagate() keys:SetPropagateKeyboardInput(true) end
if InCombatLockdown() then
  keys:EnableKeyboard(false)
  keys:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    Propagate()
    self:EnableKeyboard(true)
  end)
  keys:RegisterEvent("PLAYER_REGEN_ENABLED")
else
  Propagate()
end

------------------------------------------------------------------------------ tooltip
local function Pair(left, right, r, g, b)
  local c = NORMAL_FONT_COLOR
  GameTooltip:AddDoubleLine(left, right, c.r, c.g, c.b, r or 1, g or 1, b or 1)
end

local function ShiftHint()
  if GameTooltip.meioShiftHint then return end
  GameTooltip.meioShiftHint = true
  GameTooltip:AddLine(MUTED .. "Shift: more|r")
end

local function ShortUses()
  local names = {}
  for _, use in ipairs(USES) do
    if use.short and known[use] then names[#names + 1] = use.label end
  end
  return table.concat(names, ", ")
end

local function Detail()
  GameTooltip:AddLine(" ")
  for _, use in ipairs(USES) do
    local id = known[use]
    if id then
      local name = C_Spell.GetSpellName(id) or use.label
      if use.perCast then
        Pair(name, "1 per cast")
      elseif Carries(use) then
        Pair(name, "have one", 0.5, 1, 0.5)
      else
        Pair(name, "1 shard")
      end
    end
  end
  if KnowsAny() then GameTooltip:AddLine(" ") end
  local cap = Cap()
  Pair("Keep at most", cap and tostring(cap) or "off")
  Pair("No room in soul bag", db.overflow and "delete" or "keep")
  Pair("Auto delete extras", db.auto and "on" or "off")
  Pair("Warn below", db.warn > 0 and tostring(db.warn) or "off")
  local key = GetBindingKey("SHARDKEEPER_TRIM")
  Pair("Delete key", key and GetBindingText(key) or "not bound", key and 1 or 0.6,
    key and 1 or 0.6, key and 1 or 0.6)
  if tipOwner == frame then
    GameTooltip:AddLine(MUTED .. "Shift-drag to move. " .. SLASH .. " for options.|r")
  else
    GameTooltip:AddLine(MUTED .. "Right-click for options.|r")
  end
end

ShowTooltip = function(owner)
  tipOwner = owner or frame
  if tipOwner == frame then
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
  else
    -- broker bars sit at the top or bottom edge: open away from it
    local _, y = tipOwner:GetCenter()
    local top = y and y * tipOwner:GetEffectiveScale() > UIParent:GetHeight()
      * UIParent:GetEffectiveScale() / 2
    GameTooltip:SetOwner(tipOwner, "ANCHOR_NONE")
    GameTooltip:SetPoint(top and "TOP" or "BOTTOM", tipOwner, top and "BOTTOM" or "TOP")
  end
  local low = count < Needed()
  local r, g, b = 1, 1, 1
  if low then r, g, b = 1, 0.5, 0.5 end
  GameTooltip:AddDoubleLine("Soul Shards", tostring(count), 1, 1, 1, r, g, b)
  for _, p in ipairs(perBag) do Pair(BagName(p.bag), tostring(p.count)) end
  local uses = ShortUses()
  if uses ~= "" then
    if count > 0 then
      GameTooltip:AddLine(GOLD .. "Can make:|r " .. uses, 1, 1, 1, true)
    else
      GameTooltip:AddLine(BAD .. "Needs a shard:|r " .. uses, 1, 1, 1, true)
    end
  end
  if low then
    GameTooltip:AddLine("Drain Soul a mob as it dies for more.", 1, 0.5, 0.5, true)
  end
  local extra = Extra()
  if extra > 0 then
    local why = overflow >= AboveCap() and "no room in your soul bag"
      or ("above the cap of %d"):format(Cap())
    local key = GetBindingKey("SHARDKEEPER_TRIM")
    GameTooltip:AddLine(("Click%s: delete %d (%s)"):format(key and " or " .. GetBindingText(key)
      or "", extra, why), 1, 0.82, 0, true)
    local auto = AutoExtra()
    if auto > 0 then
      GameTooltip:AddLine(("%d go%s by %s on your next key press%s"):format(auto,
        auto == 1 and "es" or "", auto == 1 and "itself" or "themselves",
        InCombat() and " after the fight" or ""), 0.6, 0.6, 0.6, true)
    end
  end
  if IsShiftKeyDown() then Detail() else ShiftHint() end
  GameTooltip:Show()
end

GameTooltip:HookScript("OnTooltipCleared", function(tip) tip.meioShiftHint = nil end)

frame:SetScript("OnEnter", function(self)
  ShowTooltip()
  self:RegisterEvent("MODIFIER_STATE_CHANGED")
end)
frame:SetScript("OnLeave", function(self)
  self:UnregisterEvent("MODIFIER_STATE_CHANGED")
  GameTooltip_Hide()
end)
frame:SetScript("OnEvent", function()
  if TooltipOpen() then ShowTooltip(tipOwner) end
end)
frame:SetScript("OnDragStart", function(self)
  if not IsShiftKeyDown() then return end
  self.moving = true
  self:StartMoving()
end)
frame:SetScript("OnDragStop", function(self)
  if not self.moving then return end
  self.moving = false
  self.dragEnd = GetTime()
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(1)
  db.point = { p, rp, math.floor(x + 0.5), math.floor(y + 0.5) }
  Place()
end)
frame:SetScript("OnClick", function(self)
  if self.dragEnd and GetTime() - self.dragEnd < DRAG_CLICK_GUARD then return end
  if Extra() > 0 then Trim() end
end)

------------------------------------------------------------------------------ public
MeioShards = {
  Trim = Trim,
  Key = Key,
  Count = function() return count end,
  Cap = Cap,
  WantsMore = function() local cap = Cap() return not cap or count < cap end,
}
_G.ShardKeeper = MeioShards -- old name, still called by other addons and macros
BINDING_HEADER_SHARDKEEPER = "MeioShards"
BINDING_NAME_SHARDKEEPER_TRIM = "Delete extra Soul Shards, else the cheapest junk item"

ns.DEFAULTS = DEFAULTS
ns.settings = settings
ns.Update = Update
ns.Place = Place
function ns.DB() return db end

-- through the Settings panel's setting when there is one, so an open panel shows it
local function Set(key, value)
  if settings[key] then settings[key]:SetValue(value) else db[key] = value end
  Update()
end

------------------------------------------------------------------------------ slash
local function Help()
  Print("deletes the Soul Shards over your cap with a key, and warns when you run low")
  local cap = Cap()
  Line(Cmd(SLASH .. " cap <n>||off") .. " - keep at most n; press the key for the rest (now "
    .. (cap or "off") .. ")")
  Line(Cmd(SLASH .. " auto on||off") .. " - new: delete extras on your next key press, never"
    .. " in combat or the shards you brought (now " .. OnOff(db.auto) .. ")")
  Line(Cmd(SLASH .. " trim") .. " - delete the extras now; quiet, for your Drain Soul macro."
    .. " Key: " .. KEY_PATH)
  Line(Cmd(SLASH .. " overflow on||off") .. " - also delete loose shards your full soul bag"
    .. " has no room for (now " .. OnOff(db.overflow) .. ")")
  Line(Cmd(SLASH .. " warn <n>||off") .. " - low below n shards (now "
    .. (db.warn > 0 and db.warn or "off") .. ")")
  Line(Cmd(SLASH .. " chat on||off") .. " - a chat line when you run low (now "
    .. OnOff(db.chat) .. ")")
  Line(Cmd(SLASH .. " show on||off") .. " - your shard count on screen (now " .. OnOff(db.show)
    .. ")")
  Line(Cmd(SLASH .. " reset") .. " - put the counter back (Shift-drag it to move it)")
  Line("Settings: " .. SETTINGS_PATH .. " (" .. Cmd(SLASH .. " settings") .. ")")
end

local function OpenSettings()
  if category then Settings.OpenToCategory(category:GetID()) else Help() end
end
function ns.SetCategory(c) category = c end

function MeioShards_OnAddonCompartmentClick() OpenSettings() end

-- "off" -> 0, a number in range -> it, else nil
local function Number(arg, max)
  if arg == "off" then return 0 end
  local n = tonumber(arg)
  if n and n >= 0 and n <= max then return math.floor(n) end
end

SLASH_MEIOSHARDS1 = SLASH
SlashCmdList.MEIOSHARDS = function(msg)
  local word, arg = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")
  if not isWarlock then
    Print("only for warlocks")
    return
  end
  if word == "" or word == "help" or word == "?" then
    Help()
  elseif word == "settings" or word == "options" then
    OpenSettings()
  elseif word == "trim" then
    Trim(true)
  elseif word == "cap" then
    local n = Number(arg, ns.CAP_MAX)
    if not n then
      Print("cap takes a number from 1 to " .. ns.CAP_MAX .. ", or off")
      return
    end
    Set("cap", n)
    if n == 0 then
      Print("cap " .. OnOff(false))
    else
      Print(("keeping at most %d Soul Shards"):format(n)
        .. (AboveCap() > 0 and (", " .. AboveCap() .. " above it: press the key") or ""))
    end
  elseif word == "warn" then
    local n = Number(arg, ns.WARN_MAX)
    if not n then
      Print("warn takes a number from 1 to " .. ns.WARN_MAX .. ", or off")
      return
    end
    Set("warn", n)
    Print(n == 0 and "low warning " .. OnOff(false)
      or ("low warning below %d Soul Shard%s"):format(n, n == 1 and "" or "s"))
  elseif (word == "chat" or word == "show" or word == "overflow" or word == "auto")
      and (arg == "on" or arg == "off") then
    Set(word, arg == "on")
    local what = { chat = "chat line when low ", show = "counter ",
      overflow = "deleting shards your soul bag has no room for ",
      auto = "auto delete extras " }
    Print(what[word] .. OnOff(arg == "on"))
  elseif word == "reset" then
    db.point = nil
    Place()
    Print("counter back in its place")
  else
    Print('unknown command "' .. word .. '"')
    Help()
  end
end

------------------------------------------------------------------------------ data broker
-- A feed for Titan Panel, ChocolateBar and other broker bars. No library of our own: every
-- broker display embeds LibDataBroker, so with no display there is nothing to feed.
local function RegisterBroker()
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  if not ldb or ldb:GetDataObjectByName(ADDON) then return end
  broker = ldb:NewDataObject(ADDON, {
    type = "data source",
    label = "Soul Shards",
    text = "0",
    icon = icon:GetTexture(),
    OnClick = function(_, button)
      if button == "RightButton" then OpenSettings() elseif Extra() > 0 then Trim() end
    end,
    OnEnter = function(display)
      ShowTooltip(display)
      frame:RegisterEvent("MODIFIER_STATE_CHANGED")
    end,
    OnLeave = function()
      frame:UnregisterEvent("MODIFIER_STATE_CHANGED")
      GameTooltip_Hide()
    end,
  })
end

------------------------------------------------------------------------------ events
local CLOSES = {}
for open, close in pairs(SOURCES) do CLOSES[close] = open end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    MeioShardsDB = MeioShardsDB or {}
    db = MeioShardsDB
    if (db.version or 1) < DB_VERSION and db.show then
      db.show, db.chat = false, true
    end
    db.version = DB_VERSION
    for k, v in pairs(DEFAULTS) do
      if db[k] == nil then db[k] = v end
    end
  elseif event == "PLAYER_LOGIN" then
    isWarlock = select(2, UnitClass("player")) == "WARLOCK"
    if not isWarlock then return end
    loginAt = GetTime()
    Style()
    Place()
    LearnSpells()
    local ok, err = pcall(ns.RegisterSettings)
    if not ok then geterrorhandler()(err) end
    ok, err = pcall(RegisterBroker)
    if not ok then geterrorhandler()(err) end
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    for open, close in pairs(SOURCES) do
      pcall(self.RegisterEvent, self, open)
      pcall(self.RegisterEvent, self, close)
    end
    -- Edit Mode applies the bags bar's spot after login
    pcall(self.RegisterEvent, self, "EDIT_MODE_LAYOUTS_UPDATED")
    Update()
  elseif event == "EDIT_MODE_LAYOUTS_UPDATED" then
    Place()
  elseif SOURCES[event] then
    sourcing[event] = true
  elseif CLOSES[event] then
    sourcing[CLOSES[event]] = nil
    sourceUntil = GetTime() + SOURCE_GRACE
  else
    if event == "PLAYER_ENTERING_WORLD" then mapRefused = false end
    if event == "SPELLS_CHANGED" then LearnSpells() end
    Update()
  end
end)
