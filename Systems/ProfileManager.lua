-- ThreatSense: ProfileManager.lua
-- Central profile system for all addon settings

local ADDON_NAME, TS = ...
TS.ProfileManager = {}
local PM = TS.ProfileManager

------------------------------------------------------------
-- Ensure DB structure exists
------------------------------------------------------------
local function EnsureDB()
    ThreatSenseDB = ThreatSenseDB or {}
    ThreatSenseDB.profiles = ThreatSenseDB.profiles or {}
    ThreatSenseDB.profileKeys = ThreatSenseDB.profileKeys or {}

    -- Create default profile if missing
    if not ThreatSenseDB.profiles["Default"] then
        ThreatSenseDB.profiles["Default"] = {}
    end
end

------------------------------------------------------------
-- Get active profile name for this character
------------------------------------------------------------
function PM:GetActiveProfileName()
    local key = UnitName("player") .. " - " .. GetRealmName()
    return ThreatSenseDB.profileKeys[key] or "Default"
end

------------------------------------------------------------
-- Get active profile table
------------------------------------------------------------
function PM:GetProfile()
    EnsureDB()
    local name = self:GetActiveProfileName()
    return ThreatSenseDB.profiles[name]
end

------------------------------------------------------------
-- Set active profile
------------------------------------------------------------
function PM:SetActiveProfile(name)
    EnsureDB()
    if not ThreatSenseDB.profiles[name] then return end

    local key = UnitName("player") .. " - " .. GetRealmName()
    ThreatSenseDB.profileKeys[key] = name

    TS.Utils:Debug("Profile switched to: " .. name)

    -- Notify all modules
    TS.EventBus:Emit("PROFILE_CHANGED", name)
end

------------------------------------------------------------
-- Create a new profile
------------------------------------------------------------
function PM:CreateProfile(name)
    EnsureDB()
    if ThreatSenseDB.profiles[name] then return false end

    ThreatSenseDB.profiles[name] = {}
    return true
end

------------------------------------------------------------
-- Copy an existing profile
------------------------------------------------------------
function PM:CopyProfile(source, target)
    EnsureDB()
    if not ThreatSenseDB.profiles[source] then return false end

    ThreatSenseDB.profiles[target] = CopyTable(ThreatSenseDB.profiles[source])
    return true
end

------------------------------------------------------------
-- Delete a profile
------------------------------------------------------------
function PM:DeleteProfile(name)
    EnsureDB()
    if name == "Default" then return false end
    ThreatSenseDB.profiles[name] = nil
    return true
end

------------------------------------------------------------
-- Save a setting into the active profile
------------------------------------------------------------
function PM:Set(key, value)
    local profile = self:GetProfile()
    profile[key] = value

    TS.EventBus:Emit("PROFILE_SETTING_CHANGED", key, value)
end

------------------------------------------------------------
-- Read a setting from the active profile
------------------------------------------------------------
function PM:Get(key, default)
    local profile = self:GetProfile()
    local value = profile[key]
    if value == nil then return default end
    return value
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function PM:Initialize()
    EnsureDB()
    TS.Utils:Debug("ProfileManager initialized")
end

return PM