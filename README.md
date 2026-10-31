# EllesmereUI Level Color Tooltip

A small companion add-on for **EllesmereUI** on **WoW Forever**. It colours the level on unit tooltips by level range, so you can see at a glance how hard a mob or player is compared to you.

## What it does

When you hover a unit, the level on its tooltip gets a colour. The game uses the same scale for quest and creature difficulty:

| Colour | Meaning |
|---|---|
| Red | 5 or more levels above you, or `??` (skull / boss) |
| Orange | 3–4 levels above you |
| Yellow | Within 2 levels of you |
| Green | Lower than you, but still gives XP |
| Grey | Trivial (no XP) |

```
Defias Pillager
Level 18 Humanoid        <- "18" is orange when you are level 15
```

- **What gets the colour.** Pick one of three options:
  - only the number (`60`), the default
  - the number and the word before it (`Level 60`)
  - the whole level line
- **Custom colours.** All five range colours can be changed. The defaults are Blizzard's own difficulty colours.
- **Players.** Player levels are coloured too by default. You can switch that off, and then only NPCs and creatures are coloured.
- **Works everywhere.** The level is read from the tooltip text itself, so it also works when you hover EllesmereUI raid or party frames.
- **No stacking.** When the tooltip refreshes, the colour is replaced and not added a second time.

The add-on changes no EllesmereUI file, so **EllesmereUI updates do not remove it**.

## Installation

1. Download this repository and put the `EllesmereUI_LevelColorTooltip` folder into your add-ons folder:
   `World of Warcraft\_classic_beta_\Interface\AddOns\`
   (or the `Interface\AddOns` folder of whichever client you play).
2. **Fully restart the game.** A `/reload` isn't enough for a newly added add-on folder.
3. Make sure **EllesmereUI Level Color Tooltip** is enabled in the add-on list on the character screen.

Requires **EllesmereUI**. **EllesmereUI Dworak** is optional: it provides the settings page. Without it the tooltip colours still work, and you change the settings with the chat commands.

## Settings

EllesmereUI panel → **Dworak → Level Color Tooltip**

| Option | Effect |
|---|---|
| **Level Color on Tooltip** | Turns the feature on or off. Click the cog next to it to set the five range colours. |
| **Color** | Level Number / Level + Number / Whole Line |
| **Color Player Levels** | When off, only NPCs and creatures are coloured. |
| **Reset Colors** | Restores the default range colours. |

## Commands

| Command | Effect |
|---|---|
| `/levelcolor` | Opens the settings page. Without EllesmereUI Dworak it prints the current status instead. |
| `/levelcolor on` / `off` | Turns the colouring on or off |
| `/levelcolor number` | Colours only the number |
| `/levelcolor label` | Colours `Level 60` |
| `/levelcolor line` | Colours the whole level line |
| `/levelcolor players` | Turns colouring of player levels on or off |

Settings are account-wide and saved in `EllesmereUI_LevelColorTooltipDB`.

## Compatibility

- Built for **EllesmereUI 9.6.6** on WoW Forever (interface 16001). The `.toc` also lists the retail interface versions EllesmereUI supports.
- Works together with the EllesmereUI tooltip skin. That skin recolours the name line and the guild line, but it doesn't touch the level line.
- The level line is found through the client's own `TOOLTIP_UNIT_LEVEL` string (`Level %s`), so it also works on localised clients.

## Files

```
EllesmereUI_LevelColorTooltip/
├── EllesmereUI_LevelColorTooltip.toc
├── LevelColorTooltip.lua          core: settings, tooltip hook, /levelcolor
├── LevelColorTooltip_Options.lua  settings page (Dworak > Level Color Tooltip)
└── README.md
```

## How it works (for developers)

- **Hook.** The add-on registers a post-call with `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, ...)` for `GameTooltip`. On clients without it, it falls back to `OnTooltipSetUnit`. Each call is wrapped in `pcall`.
- **Finding the line.** `TOOLTIP_UNIT_LEVEL` is split at `%s` into a prefix and a suffix (`"Level "`, `""`). Tooltip lines 2–8 are checked for that prefix, followed by a number or `??`. Locales that put the number first are handled too.
- **Secret values.** No unit token is used. The level number is parsed from the line text, and secret texts and GUIDs are skipped through `issecretvalue`.
- **Range rule.** This is the same rule as Blizzard's `GetRelativeDifficultyColor`:
  - `diff >= 5` → red
  - `diff >= 3` → orange
  - `diff >= -2` → yellow
  - `-diff <= GetQuestGreenRange()` → green
  - otherwise → grey

  The player's own level comes from `UnitEffectiveLevel("player")`, with `UnitLevel` as a fallback. `GetQuestGreenRange` falls back to `UnitQuestTrivialLevelRange`, and then to the classic grey-level formula.
- **Colouring.** The colour is added with inline `|cff…|r` codes. On a refresh pass, a colour code the add-on wrote earlier is detected and replaced, so switching between Number, Label and Line never leaves stray codes.
- **Player check.** When **Color Player Levels** is off, a unit counts as a player if its GUID starts with `Player-`.

## Disclaimer

This is an unofficial fan-made add-on. It isn't affiliated with or supported by the EllesmereUI author. Please report problems with it here, not to EllesmereUI.
