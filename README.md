# Meio Shards

One key deletes the Soul Shards you don't need, and a chat line tells you when you run out.

For WoW Forever.

![Warlock bags: before, Soul Shards scattered among the loot and a full Soul Pouch; one
press of the Meio Shards key later, the 7 loose shards the pouch has no room for are gone
and a chat line says "deleted 7 Soul Shards, kept 8"](docs/before-after.png)

## What it does

Press its key to delete the shards you don't want. Out of the box it only deletes when you
press the key, never on its own.

- Deletes the loose shards your full Soul Pouch has no room for, and any above your cap
  (20 by default), then moves loose shards that fit into the pouch
- Never deletes in combat or a boss fight: it says "not in combat" instead of an error
- A chat line when you run out of shards
- Shows on Titan Panel, ChocolateBar and other data broker bars: count, shards per bag and
  what you can make with them, click to delete extras, right click for settings

![The count on a data broker bar, 22 of a cap of 20, its tooltip below: shards per bag,
what they can make and "Click: delete 2 (no room in your soul bag)"](docs/broker.png)

- With no shard to delete, the key deletes your cheapest junk item instead (Meio Bags, or
  RestedXP Guides' "Delete Cheapest Junk Item")
- Want the count on screen? `/shards show on` puts a small counter beside your bag buttons

New, off by default: extras that go by themselves on your next key press or click, never
in combat and never the shards you brought from the bank; in dungeons, once you leave. It
isn't tested in a live game yet, so it starts off. Try it with `/shards auto on` and tell us
how it goes.

Settings: Esc > Options > AddOns > MeioShards, or `/shards settings`. Delete key:
Esc > Options > Keybindings > AddOns > MeioShards.

- `/shards trim`: delete the extra shards now; quiet, so it fits in your Drain Soul macro
- `/shards cap <n>|off`: keep at most n shards
- `/shards auto on|off`: delete extras by themselves (off by default)
- `/shards overflow on|off`: also delete shards your full soul bag has no room for
- `/shards warn <n>|off`: low below n shards
- `/shards chat on|off`: a chat line when you run low
- `/shards show on|off`: your shard count on screen (off by default)
- `/shards reset`: put the counter back beside your bag buttons
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
