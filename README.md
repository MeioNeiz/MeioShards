# Meio Shards

Your Soul Shard count always on screen, and one click or key to clear out the extras.

For WoW Forever.

![Warlock bags: before, Soul Shards scattered among the loot to count by hand; with Meio
Shards, a counter above the bags showing 15, its tooltip listing shards per bag, what they
can make and "Click: delete 7 (no room in your soul bag)"; one click later, the counter at 8
and a chat line "deleted 7 Soul Shards, kept 8"](docs/before-after.png)

## What it does

A small counter shows how many Soul Shards you carry. Hover it for the detail; click it (or
press its key) to delete the shards you don't want. Out of the box it only deletes when you
click or press its key, never on its own.

- Deletes the loose shards your full Soul Pouch has no room for, and any above your cap
  (20 by default), then moves loose shards that fit into the pouch
- Never deletes in combat or a boss fight: it says "not in combat" instead of an error
- Turns red when you run low, with an optional chat line
- Tooltip: shards per bag and what you can make with them; Shift for each spell's cost
- Shows on Titan Panel, ChocolateBar and other data broker bars: count, tooltip, click to
  delete extras, right click for settings
- With no shard to delete, the key deletes your cheapest junk item instead (Meio Bags, or
  RestedXP Guides' "Delete Cheapest Junk Item")
- Sits beside the bag buttons; Shift-drag to move it

New, off by default: extras that go by themselves on your next key press or click, never
in combat and never the shards you brought from the bank; in dungeons, once you leave. It
isn't tested in a live game yet, so it starts off. Try it with `/shards auto on` and tell us
how it goes.

Settings: Esc > Options > AddOns > MeioShards, or `/shards settings`. Delete key:
Esc > Options > Keybindings > AddOns > MeioShards.

- `/shards cap <n>|off`: keep at most n shards
- `/shards trim`: delete the extra shards now; quiet, so it fits in your Drain Soul macro
- `/shards auto on|off`: delete extras by themselves (off by default)
- `/shards overflow on|off`: also delete shards your full soul bag has no room for
- `/shards warn <n>|off`: the counter turns red below n shards
- `/shards chat on|off`: a chat line when it turns red
- `/shards show on|off`: show or hide the counter
- `/shards reset`: put the counter back in its place
- `/shards help`

## Install

Use your addon manager (CurseForge, Wago), or unzip a GitHub release into
`World of Warcraft\_forever_\Interface\AddOns` and restart WoW fully.

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/MeioNeiz/MeioShards/issues)

## More Meio addons

[Meio Trainer Compare](https://www.curseforge.com/wow/addons/trainercompare) | [Meio Next Stop](https://www.curseforge.com/wow/addons/leavebutton) | [Meio Auto Rank](https://www.curseforge.com/wow/addons/meio-autorank) | [Meio Meter Hover](https://www.curseforge.com/wow/addons/meterhover) | [Meio Map](https://addons.wago.io/addons/meiomap) | [Meio Alts](https://addons.wago.io/addons/meioalts) | [Meio DPS](https://addons.wago.io/addons/meiodps) | [Meio Plates](https://addons.wago.io/addons/meioplates) | [Meio Hub](https://addons.wago.io/addons/meiohub) | [Meio Pets](https://addons.wago.io/addons/meiopets) | [Meio Stats](https://addons.wago.io/addons/meiostats) | [Meio Bags](https://addons.wago.io/addons/meiobags) | [Meio Fixes](https://addons.wago.io/addons/meiofixes) | [Meio Flight Times](https://addons.wago.io/addons/meioflighttimes) | [Meio Tooltip Fold](https://addons.wago.io/addons/meiotooltipfold) | [Meio Auto Run Turn](https://addons.wago.io/addons/meioautorunturn) | [Meio Mail](https://addons.wago.io/addons/meiomail) | [Meio QoL](https://addons.wago.io/addons/meioqol) | [Meio TSM Browse](https://addons.wago.io/addons/tsmbrowse) | [Meio Spike Check](https://addons.wago.io/addons/meiospikecheck) | [Meio BiS Extras](https://addons.wago.io/addons/meiobisextras) | [Meio Buff Thanks](https://addons.wago.io/addons/meiobuffthanks) | [Meio Flare Fixes](https://addons.wago.io/addons/meioflarefixes) | [Meio Flare Questie](https://addons.wago.io/addons/meioflarequestie)

## Licence

[MIT](LICENSE)
