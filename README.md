# Meio Shard Keeper

Your Soul Shard count always on screen, and one click or key to clear out the extras.

![Warlock bags: before, Soul Shards scattered among the loot to count by hand; with Shard
Keeper, a counter above the bags showing 15, its tooltip listing shards per bag, what they
can make and "Click: delete 7 (no room in your soul bag)"](docs/before-after.png)

## What it does

A small counter shows how many Soul Shards you carry. Hover it for the detail; click it (or
press its key) to delete the shards you don't want.

- Deletes the loose shards your full Soul Pouch has no room for, and any above your cap
  (20 by default), then moves loose shards that fit into the pouch
- Turns red when you run low, with an optional chat line
- Tooltip: shards per bag and what you can make with them; Shift for each spell's cost
- With no shard to delete, the key deletes your cheapest junk item instead (Meio Bags, or
  RestedXP Guides' "Delete Cheapest Junk Item")
- Sits beside the bag buttons; Shift-drag to move it

Settings: Esc > Options > AddOns > ShardKeeper, or `/shards settings`. Delete key:
Esc > Options > Keybindings > AddOns > ShardKeeper.

- `/shards cap <n>|off`: keep at most n shards
- `/shards overflow on|off`: also delete shards your full soul bag has no room for
- `/shards trim`: delete the extra shards now
- `/shards warn <n>|off`: the counter turns red below n shards
- `/shards chat on|off`: a chat line when it turns red
- `/shards show on|off`: show or hide the counter
- `/shards reset`: put the counter back in its place
- `/shards help`

## Install

Use your addon manager (CurseForge, Wago), or unzip a GitHub release into
`World of Warcraft\_forever_\Interface\AddOns` and restart WoW fully.

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/MeioNeiz/ShardKeeper/issues)

## More Meio addons

[Meio TrainerCompare](https://www.curseforge.com/wow/addons/trainercompare) | [Meio Next Stop](https://www.curseforge.com/wow/addons/leavebutton) | [Meio AutoRank](https://www.curseforge.com/wow/addons/meio-autorank) | [Meio MeterHover](https://www.curseforge.com/wow/addons/meterhover) | [Meio Map](https://addons.wago.io/addons/meiomap) | [Meio Alts](https://addons.wago.io/addons/meioalts) | [Meio DPS](https://addons.wago.io/addons/meiodps) | [Meio Plates](https://addons.wago.io/addons/meioplates) | [Meio Hub](https://addons.wago.io/addons/meiohub) | [Meio Pets](https://addons.wago.io/addons/meiopets) | [Meio Stats](https://addons.wago.io/addons/meiostats) | [Meio Bags](https://addons.wago.io/addons/meiobags) | [Meio Fixes](https://addons.wago.io/addons/meiofixes) | [Meio Flight Times](https://addons.wago.io/addons/meioflighttimes)

## Licence

[MIT](LICENSE)
