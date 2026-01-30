-- ThreatSense: ProfileManager.lua
-- Central profile system with versioning, migrations, and deep defaults

local ADDON_NAME, TS = ...

TS.ProfileManager = TS.ProfileManager or {}
local PM = TS.ProfileManager

------------------------------------------------------------
-- Profile versioning
------------------------------------------------------------
PM.CURRENT_VERSION = 2

------------------------------------------------------------
-- Default profile structure
-- This is the authoritative schema for all profiles.
------------------------------------------------------------
PM.DEFAULTS = {
    version = PM.CURRENT_VERSION,

    -- Display settings
    display = {
        enabled = true,
        mode = "BAR_AND_LIST",
        width = 200,
        height = 20,
        scale = 1.0,
        maxEntries = 5,
        showText = true,
        showPercentage = true,
        barTexture = "Blizzard",
        font = "Friz Quadrata TT",
        fontSize = 12,
        colors = {
            threat = {
                safe     = { r = 0,   g = 1,   b = 0   },
                warning  = { r = 1,   g = 1,   b = 0   },
                danger   = { r = 1,   g = 0.5, b = 0   },
                critical = { r = 1,   g = 0,   b = 0   },
            }
        },
        position = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -200,
        },
    },

    -- Warning settings
    warnings = {
        enabled = true,
        style = "ICON",

        thresholds = {
            tank = {
                losingAggro = 80,
                taunt = 0,
            },
            dps = {
                pulling = 90,
                drop = 95,
            },
            healer = {
                pulling = 90,
            },
        },

        sounds = {
            AGGRO_LOST     = { enabled = true, mediaKey = "RaidWarning" },
            LOSING_AGGRO   = { enabled = true, mediaKey = "Alarm" },
            TAUNT          = { enabled = true, mediaKey = "Horn" },
            PULLING_AGGRO  = { enabled = true, mediaKey = "Warning" },
            AGGRO_PULLED   = { enabled = true, mediaKey = "Warning" },
            DROP_THREAT    = { enabled = true, mediaKey = "Bell" },
        },
    },

    -- Role-based profile switching
    autoSwitchProfiles = false,
    roleProfiles = {
        TANK = nil,
        HEALER = nil,
        DAMAGER = nil,
    },

    -- Debug
    debug = false,
}

------------------------------------------------------------
-- Utility: Deep copy
------------------------------------------------------------
local function DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

------------------------------------------------------------
-- Utility: Deep merge defaults into profile
------------------------------------------------------------
local function MergeDefaults(profile, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            profile[k] = profile[k] or {}
            MergeDefaults(profile[k], v)
        else
            if profile[k] == nil then
                profile[k] = v
            end
        end
    end
end

------------------------------------------------------------
-- Ensure DB structure exists
------------------------------------------------------------
local function EnsureDB()
    ThreatSenseDB = ThreatSenseDB or {}
    ThreatSenseDB.profiles = ThreatSenseDB.profiles or {}
    ThreatSenseDB.profileKeys = ThreatSenseDB.profileKeys or {}

    -- Create default profile if missing
    if not ThreatSenseDB.profiles["Default"] then
        ThreatSenseDB.profiles["Default"] = DeepCopy(PM.DEFAULTS)
    end
end

------------------------------------------------------------
-- Get active profile name
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
    local profile = ThreatSenseDB.profiles[name]

    -- Ensure defaults exist
    MergeDefaults(profile, PM.DEFAULTS)

    -- Run migrations if needed
    if profile.version ~= PM.CURRENT_VERSION then
        self:Migrate(profile)
    end

    return profile
end

------------------------------------------------------------
-- Set active profile
------------------------------------------------------------
function PM:SetActiveProfile(name)
    EnsureDB()
    if not ThreatSenseDB.profiles[name] then return end

    local key = UnitName("player") .. " - " .. GetRealmName()
    ThreatSenseDB.profileKeys[key] = name

    TS.EventBus:Send("PROFILE_CHANGED", name)
end

------------------------------------------------------------
-- Create a new profile
------------------------------------------------------------
function PM:CreateProfile(name)
    EnsureDB()
    if ThreatSenseDB.profiles[name] then return false end

    local role = TS.RoleManager:GetRole()
    local profile = DeepCopy(PM.DEFAULTS)

    -- Role-aware display mode defaults
    if role == "TANK" then
        profile.display.mode = "BAR_AND_LIST"
    elseif role == "HEALER" then
        profile.display.mode = "LIST_ONLY"
    else
        profile.display.mode = "BAR_ONLY"
    end

    ThreatSenseDB.profiles[name] = profile
    return true
end

------------------------------------------------------------
-- Copy an existing profile
------------------------------------------------------------
function PM:CopyProfile(source, target)
    EnsureDB()
    if not ThreatSenseDB.profiles[source] then return false end

    ThreatSenseDB.profiles[target] = DeepCopy(ThreatSenseDB.profiles[source])
    return true
end

------------------------------------------------------------
-- Rename a profile
------------------------------------------------------------
function PM:RenameProfile(oldName, newName)
    EnsureDB()
    if not ThreatSenseDB.profiles[oldName] then return false end
    if ThreatSenseDB.profiles[newName] then return false end

    ThreatSenseDB.profiles[newName] = ThreatSenseDB.profiles[oldName]
    ThreatSenseDB.profiles[oldName] = nil

    -- Update profileKeys
    for key, profile in pairs(ThreatSenseDB.profileKeys) do
        if profile == oldName then
            ThreatSenseDB.profileKeys[key] = newName
        end
    end

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
-- Export profile as a serialized string
------------------------------------------------------------
function PM:ExportProfile(name)
    EnsureDB()
    local profile = ThreatSenseDB.profiles[name]
    if not profile then return nil end

    return LibSerialize:Serialize(profile)
end

------------------------------------------------------------
-- Import profile from serialized string
------------------------------------------------------------
function PM:ImportProfile(name, data)
    EnsureDB()
    if ThreatSenseDB.profiles[name] then return false end

    local success, decoded = LibSerialize:Deserialize(data)
    if not success or type(decoded) ~= "table" then
        return false
    end

    MergeDefaults(decoded, PM.DEFAULTS)
    ThreatSenseDB.profiles[name] = decoded
    return true
end

------------------------------------------------------------
-- Save a setting into the active profile
------------------------------------------------------------
function PM:Set(path, value)
    local profile = self:GetProfile()

    -- Support nested keys: "display.width"
    local t = profile
    local segments = { strsplit(".", path) }
    for i = 1, #segments - 1 do
        local key = segments[i]
        t[key] = t[key] or {}
        t = t[key]
    end

    t[segments[#segments]] = value

    TS.EventBus:Send("PROFILE_SETTING_CHANGED", path, value)
end

------------------------------------------------------------
-- Read a setting from the active profile
------------------------------------------------------------
function PM:Get(path, default)
    local profile = self:GetProfile()

    local t = profile
    for segment in string.gmatch(path, "[^%.]+") do
        t = t[segment]
        if t == nil then return default end
    end

    return t
end

------------------------------------------------------------
-- Migration system
------------------------------------------------------------
function PM:Migrate(profile)
    local oldVersion = profile.version or 1

    if oldVersion < 2 then
        -- Example migration: ensure new fields exist
        profile.warnings = profile.warnings or DeepCopy(PM.DEFAULTS.warnings)
        profile.display = profile.display or DeepCopy(PM.DEFAULTS.display)
    end

    profile.version = PM.CURRENT_VERSION
end

------------------------------------------------------------
-- Auto-switch profiles when role changes
------------------------------------------------------------
TS.EventBus:Register("ROLE_CHANGED", function(newRole)
    local auto = PM:Get("autoSwitchProfiles", false)
    if not auto then return end

    local roleProfiles = PM:Get("roleProfiles", {})
    local targetProfile = roleProfiles[newRole]

    if targetProfile and ThreatSenseDB.profiles[targetProfile] then
        PM:SetActiveProfile(targetProfile)
    end
end)

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function PM:Initialize()
    EnsureDB()
    TS.EventBus:Send("PROFILE_LOADED", self:GetActiveProfileName())
end

return PM