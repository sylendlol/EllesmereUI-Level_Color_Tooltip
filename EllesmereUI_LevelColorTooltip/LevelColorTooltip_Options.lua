-------------------------------------------------------------------------------
--  LevelColorTooltip_Options.lua
--  The "Level Color Tooltip" row of the "Dworak" sidebar section (registered
--  by EllesmereUIDworak through EllesmereUI's Plugin API).
--    Level Color on Tooltip (toggle + inline cog: the five range colours)
--    | Color (dropdown: Level Number / Level + Number / Whole Line)
--    Color Player Levels (toggle)
--  Without EllesmereUIDworak the tooltip still works; /levelcolor sets it.
-------------------------------------------------------------------------------
local _, ns = ...
local Get, Set = ns.Get, ns.Set

local PAGE = "Level Color Tooltip"

local function Prebuilding()
    if type(EllesmereUI.IsSearchPrebuild) == "function" then
        return EllesmereUI.IsSearchPrebuild()
    end
    return EllesmereUI._prebuilding
end

local function Refresh()
    if EllesmereUI.RefreshPage then EllesmereUI:RefreshPage() end
end

local function Off() return Get("enabled") ~= true end

local function BuildPage(pageName, parent, yOffset)
    local W = EllesmereUI.Widgets
    local y = yOffset
    local _, h
    parent._showRowDivider = true

    _, h = W:SectionHeader(parent, "LEVEL COLOR", y);  y = y - h

    local mainRow
    mainRow, h = W:DualRow(parent, y,
        { type = "toggle", text = "Level Color on Tooltip",
          tooltip = "Colour the level on unit tooltips by level range, like quest and mob difficulty: "
              .. "red = 5+ levels above you or ??, orange = 3-4 above, yellow = within 2 levels, "
              .. "green = lower but still gives XP, grey = trivial.",
          getValue = function() return Get("enabled") == true end,
          setValue = function(v)
              Set("enabled", v and true or false)
              Refresh()
          end },
        { type = "dropdown", text = "Color",
          tooltip = "What gets the colour: only the number, the \"Level 60\" text, or the whole level line.",
          values = ns.SCOPES, order = ns.SCOPE_ORDER,
          disabled = Off, disabledTooltip = "Level Color on Tooltip",
          getValue = function() return Get("scope") end,
          setValue = function(v) Set("scope", v) end }
    );  y = y - h

    if not Prebuilding() and EllesmereUI.BuildInlineCog then
        local rows = {}
        for _, c in ipairs(ns.COLOR_KEYS) do
            local key = c.key
            rows[#rows + 1] = { type = "colorpicker", label = c.label,
                get = function() return ns.GetColor(key) end,
                set = function(r, g, b) ns.SetColor(key, r, g, b) end }
        end
        EllesmereUI.BuildInlineCog(mainRow._leftRegion, {
            chain = false,
            disabled = Off,
            disabledTooltip = "Level Color on Tooltip",
            title = "Level Range Colors",
            rows = rows,
        })
    end

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Color Player Levels",
          tooltip = "Also colour the level of players. Off: only NPCs and creatures.",
          disabled = Off, disabledTooltip = "Level Color on Tooltip",
          getValue = function() return Get("players") == true end,
          setValue = function(v) Set("players", v and true or false) end },
        { type = "button", text = "Reset Colors",
          disabled = Off, disabledTooltip = "Level Color on Tooltip",
          onClick = function()
              ns.ResetColors()
              if EllesmereUI.InvalidatePageCache then EllesmereUI:InvalidatePageCache() end
              Refresh()
          end }
    );  y = y - h

    return math.abs(y)
end

local DW = EllesmereUIDworak
if not (DW and DW.AddModule) then return end  -- tooltip still works; /levelcolor for settings

DW.AddModule({
    key         = "LevelColorTooltip",
    title       = "Level Color Tooltip",
    order       = 30,
    description = "Colours the level on unit tooltips by level range.",
    pages       = { PAGE },
    buildPage   = BuildPage,
    onReset = function()
        ns.Reset()
        if EllesmereUI.InvalidatePageCache then EllesmereUI:InvalidatePageCache() end
    end,
})

function ns.OpenOptions()
    return DW.Open("LevelColorTooltip") and true or false
end

function ns.RefreshOptions()
    if EllesmereUI.InvalidatePageCache then pcall(EllesmereUI.InvalidatePageCache, EllesmereUI) end
end
