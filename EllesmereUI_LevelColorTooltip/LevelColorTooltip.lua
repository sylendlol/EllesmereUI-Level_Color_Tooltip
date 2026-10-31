-------------------------------------------------------------------------------
--  EllesmereUI_LevelColorTooltip   (standalone add-on, no EllesmereUI file edited)
--
--  Colours the level on unit tooltips (GameTooltip) by level range, the same
--  scale the game uses for quest and creature difficulty:
--    red     target is 5+ levels above you, and "??" (skull / boss)
--    orange  3-4 levels above
--    yellow  within 2 levels
--    green   below you, still gives XP
--    grey    trivial (no XP)
--  "Color" scope:  number = only "60"   label = "Level 60"   line = whole line
--
--  How: TooltipDataProcessor Unit post-call (runs after EllesmereUI's own
--  tooltip post-call). The level line is found by its text (the client's
--  TOOLTIP_UNIT_LEVEL format, "Level %s"), the number is read from the text
--  itself, so no unit token is needed (works on raid/party frame hovers and
--  never touches secret values). Refresh passes re-run it; an earlier colour
--  of ours is replaced, never stacked.
--
--  Settings: own SavedVariables (EllesmereUI_LevelColorTooltipDB), so an
--  EllesmereUI update cannot remove them.
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DEFAULTS = {
    enabled = true,
    scope   = "number",       -- number | label | line
    players = true,           -- colour player levels too (not only NPCs)
    -- Blizzard QuestDifficultyColors
    cImpossible = { r = 1.00, g = 0.10, b = 0.10 },
    cHard       = { r = 1.00, g = 0.50, b = 0.25 },
    cEven       = { r = 1.00, g = 0.82, b = 0.00 },
    cEasy       = { r = 0.25, g = 0.75, b = 0.25 },
    cTrivial    = { r = 0.50, g = 0.50, b = 0.50 },
}
ns.DEFAULTS = DEFAULTS
ns.SCOPES = { number = "Level Number", label = "Level + Number", line = "Whole Line" }
ns.SCOPE_ORDER = { "number", "label", "line" }
ns.COLOR_KEYS = {
    { key = "cImpossible", label = "Much Higher (+5, ??)" },
    { key = "cHard",       label = "Higher (+3, +4)" },
    { key = "cEven",       label = "Even (-2 .. +2)" },
    { key = "cEasy",       label = "Lower (gives XP)" },
    { key = "cTrivial",    label = "Trivial (grey)" },
}

local function DB()
    local db = EllesmereUI_LevelColorTooltipDB
    if type(db) ~= "table" then
        db = {}
        EllesmereUI_LevelColorTooltipDB = db
    end
    return db
end
ns.DB = DB

function ns.Get(key)
    local v = DB()[key]
    if v == nil then v = DEFAULTS[key] end
    return v
end

function ns.Set(key, value)
    DB()[key] = value
end

function ns.GetColor(key)
    local c = DB()[key]
    if type(c) == "table" and tonumber(c.r) then return c.r, c.g, c.b end
    local d = DEFAULTS[key]
    return d.r, d.g, d.b
end

function ns.SetColor(key, r, g, b)
    DB()[key] = { r = r, g = g, b = b }
end

function ns.ResetColors()
    local db = DB()
    for _, c in ipairs(ns.COLOR_KEYS) do db[c.key] = nil end
end

function ns.Reset()
    wipe(DB())
end

local function Print(msg)
    local p = (EllesmereUI and EllesmereUI.Print) or print
    p("|cff0cd29dLevel Color:|r " .. msg)
end
ns.Print = Print

local function IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-------------------------------------------------------------------------------
--  Level range -> colour key (same rule as the game's GetRelativeDifficultyColor)
-------------------------------------------------------------------------------
local function GreenRange(playerLevel)
    if GetQuestGreenRange then
        local ok, r = pcall(GetQuestGreenRange, "player")
        if ok and tonumber(r) then return tonumber(r) end
    end
    if UnitQuestTrivialLevelRange then
        local ok, r = pcall(UnitQuestTrivialLevelRange, "player")
        if ok and tonumber(r) then return tonumber(r) end
    end
    -- Classic grey-level formula as a last resort.
    local p = playerLevel
    if p <= 5 then return p end
    local grey
    if p <= 39 then grey = p - math.floor(p / 10) - 5
    else grey = p - math.floor(p / 5) - 1 end
    return p - grey - 1
end

local function PlayerLevel()
    local lvl = (UnitEffectiveLevel and UnitEffectiveLevel("player")) or UnitLevel("player")
    if IsSecret(lvl) or not tonumber(lvl) then lvl = UnitLevel("player") end
    return tonumber(lvl) or 1
end

local function ColorKeyFor(level)
    if not level then return "cImpossible" end   -- "??"
    local diff = level - PlayerLevel()
    if diff >= 5 then return "cImpossible"
    elseif diff >= 3 then return "cHard"
    elseif diff >= -2 then return "cEven"
    elseif -diff <= GreenRange(PlayerLevel()) then return "cEasy"
    end
    return "cTrivial"
end
ns.ColorKeyFor = ColorKeyFor

local function Hex(key)
    local r, g, b = ns.GetColor(key)
    return ("ff%02x%02x%02x"):format(
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-------------------------------------------------------------------------------
--  Finding and recolouring the level line
-------------------------------------------------------------------------------
local PRE, POST   -- TOOLTIP_UNIT_LEVEL split at %s ("Level ", "")

local function InitFormat()
    local fmt = TOOLTIP_UNIT_LEVEL or ((LEVEL or "Level") .. " %s")
    local a, b = fmt:match("^(.-)%%s(.*)$")
    if not a then a, b = (LEVEL or "Level") .. " ", "" end
    PRE, POST = a, b
end

-- Reads "60", "??", "|cffxxxxxx60|r" at the start of s.
-- Returns token text (without our colour), level (nil for ??), chars consumed.
local function ReadToken(s)
    local consumed = 0
    local col = s:match("^|c%x%x%x%x%x%x%x%x")
    if col then s = s:sub(#col + 1); consumed = #col end
    local tok = s:match("^%d+") or s:match("^%?%?")
    if not tok then return nil end
    consumed = consumed + #tok
    if col and s:sub(#tok + 1, #tok + 2) == "|r" then consumed = consumed + 2 end
    return tok, tonumber(tok), consumed
end

-- Returns the new text for a level line, or nil when this line is not one.
local function Recolor(text, scope)
    local body = text
    local lineCol = body:match("^|c%x%x%x%x%x%x%x%x")   -- an earlier "line"/"label" pass
    if lineCol then body = body:sub(#lineCol + 1) end

    local pre, tok, level, rest
    if PRE ~= "" then
        if body:sub(1, #PRE) ~= PRE then return nil end
        local after = body:sub(#PRE + 1)
        local t, lv, used = ReadToken(after)
        if not t then return nil end
        pre, tok, level, rest = PRE, t, lv, after:sub(used + 1)
    else
        -- Number-first locales: "%s <word>"
        local t, lv, used = ReadToken(body)
        if not t then return nil end
        local after = body:sub(used + 1)
        local postWord = POST:match("^%s*(%S+)")
        if postWord and not after:find(postWord, 1, true) then return nil end
        pre, tok, level, rest = "", t, lv, after
    end
    -- Drop a leftover |r from an earlier whole-line/label colour.
    if lineCol then
        if rest:sub(1, 2) == "|r" then rest = rest:sub(3)
        elseif rest:sub(-2) == "|r" then rest = rest:sub(1, -3) end
    end

    local c = "|c" .. Hex(ColorKeyFor(level))
    if scope == "line" then
        return c .. pre .. tok .. rest .. "|r"
    elseif scope == "label" and PRE ~= "" then
        return c .. pre .. tok .. "|r" .. rest
    end
    return pre .. c .. tok .. "|r" .. rest
end

local function IsPlayerGUID(guid)
    if not guid or IsSecret(guid) or type(guid) ~= "string" then return nil end
    return guid:sub(1, 7) == "Player-"
end

local function LevelHook(tt, data)
    if ns.Get("enabled") ~= true then return end
    if tt ~= GameTooltip or (tt.IsForbidden and tt:IsForbidden()) then return end
    if not ns.Get("players") and data and IsPlayerGUID(data.guid) then return end
    if not PRE then InitFormat() end

    local n = tt:NumLines() or 0
    local scope = ns.Get("scope")
    for i = 2, math.min(n, 8) do
        local fs = _G["GameTooltipTextLeft" .. i]
        local text = fs and fs:GetText()
        if text and not IsSecret(text) then
            local new = Recolor(text, scope)
            if new then
                if new ~= text then fs:SetText(new) end
                return
            end
        end
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
   and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt, data)
        pcall(LevelHook, tt, data)
    end)
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tt) pcall(LevelHook, tt, nil) end)
end

-------------------------------------------------------------------------------
--  /levelcolor                       open Dworak > Level Color Tooltip
--  /levelcolor on | off
--  /levelcolor number | label | line
--  /levelcolor players               toggle player levels
-------------------------------------------------------------------------------
local function Status()
    Print((ns.Get("enabled") and "on" or "off") .. ", colour: " .. (ns.SCOPES[ns.Get("scope")] or "?")
        .. ", players: " .. (ns.Get("players") and "yes" or "no")
        .. ".  /levelcolor on | off | number | label | line | players")
end

SLASH_EUILEVELCOLOR1 = "/levelcolor"
SlashCmdList.EUILEVELCOLOR = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg == "on" or msg == "off" then
        ns.Set("enabled", msg == "on")
    elseif ns.SCOPES[msg] then
        ns.Set("scope", msg)
    elseif msg == "players" then
        ns.Set("players", not ns.Get("players"))
    elseif msg == "" and ns.OpenOptions and ns.OpenOptions() then
        return
    else
        Status()
        return
    end
    Status()
    if ns.RefreshOptions then ns.RefreshOptions() end
end
