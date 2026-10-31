# EllesmereUI Level Color Tooltip

Dworak module for EllesmereUI (WoW Forever, Interface 16001). Colours the level on unit tooltips by level range, the same scale the game uses for quest and mob difficulty:

| Colour | Meaning |
|---|---|
| Red | 5+ levels above you, or `??` (skull / boss) |
| Orange | 3-4 levels above you |
| Yellow | within 2 levels |
| Green | lower, still gives XP |
| Grey | trivial (no XP) |

Settings: EllesmereUI panel > **Dworak > Level Color Tooltip**
- **Level Color on Tooltip** on/off; the cog sets the five range colours (defaults = Blizzard's).
- **Color**: Level Number (`60` only) / Level + Number (`Level 60`) / Whole Line.
- **Color Player Levels**: off = NPCs and creatures only.
- **Reset Colors**.

Chat: `/levelcolor` (opens the page), `/levelcolor on|off|number|label|line|players`.

No EllesmereUI file is changed; settings are in `EllesmereUI_LevelColorTooltipDB`. New folder: fully restart the game (a /reload is not enough).
