-- ThreatSense: DisplayMode.lua
-- Profile-driven display mode controller with EventBus integration

local ADDON_NAME, TS = ...

TS.DisplayMode = TS.DisplayMode or {}
local DM = TS.DisplayMode

------------------------------------------------------------
-- Supported display modes
------------------------------------------------------------
DM.MODES = {
    BAR_ONLY      = "BAR_ONLY",
    LIST_ONLY     = "LIST_ONLY",
    BAR_AND_LIST  = "BAR_AND_LIST",
    AUTO          = "AUTO",        -- future-proof: role-based
}

------------------------------------------------------------
-- Resolve AUTO mode based on role
------------------------------------------------------------
local function ResolveAutoMode()
    local role = TS.RoleManager:GetRole()

    if role == "TANK" then
        return DM.MODES.BAR_AND_LIST
    elseif role == "HEALER" then
        return DM.MODES.LIST_ONLY
    else
        return DM.MODES.BAR_ONLY
    end
end

------------------------------------------------------------
-- Get current mode (resolved)
------------------------------------------------------------
function DM:Get()
    local profile = TS.db and TS.db.profile and TS.db.profile.display
    if not profile then
        return DM.MODES.BAR_ONLY
    end

    local mode = profile.mode or DM.MODES.BAR_ONLY

    if mode == DM.MODES.AUTO then
        return ResolveAutoMode()
    end

    return mode
end

------------------------------------------------------------
-- Set display mode (writes to profile)
------------------------------------------------------------
function DM:Set(mode)
    if not DM.MODES[mode] then
        TS.Utils:Debug("Invalid display mode: " .. tostring(mode))
        return
    end

    TS.ProfileManager:Set("display.mode", mode)

    TS.Utils:Debug("Display mode set to: " .. mode)

    TS.EventBus:Send("DISPLAY_MODE_CHANGED", mode)
end

------------------------------------------------------------
-- Reset to default
------------------------------------------------------------
function DM:Reset()
    local default = TS.ProfileManager.DEFAULTS.display.mode
    self:Set(default)
end

------------------------------------------------------------
-- Event handlers
------------------------------------------------------------

-- When profile changes → update display mode
local function OnProfileChanged()
    TS.EventBus:Send("DISPLAY_MODE_CHANGED", DM:Get())
end

-- When role changes → AUTO mode may need to update
local function OnRoleChanged()
    local profile = TS.db.profile.display
    if profile.mode == DM.MODES.AUTO then
        TS.EventBus:Send("DISPLAY_MODE_CHANGED", DM:Get())
    end
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function DM:Initialize()
    TS.Utils:Debug("DisplayMode 2.0 initialized")

    -- Listen for profile changes
    TS.EventBus:Register("PROFILE_CHANGED", OnProfileChanged, {
        namespace = "DisplayMode",
        source = "DisplayMode",
    })

    -- Listen for role changes (AUTO mode)
    TS.EventBus:Register("ROLE_CHANGED", OnRoleChanged, {
        namespace = "DisplayMode",
        source = "DisplayMode",
    })

    -- Emit initial mode
    TS.EventBus:Send("DISPLAY_MODE_CHANGED", DM:Get())
end

return DM