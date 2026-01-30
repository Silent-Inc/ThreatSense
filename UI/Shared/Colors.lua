-- ThreatSense: Colors.lua
-- Centralized color definitions + helpers (profile-aware)

local ADDON_NAME, TS = ...

TS.Colors = TS.Colors or {}
local C = TS.Colors

------------------------------------------------------------
-- Default static colors (fallbacks)
------------------------------------------------------------
C.DEFAULTS = {
    THREAT = {
        LOW    = { r = 0.10, g = 1.00, b = 0.10 },
        MEDIUM = { r = 1.00, g = 0.80, b = 0.10 },
        HIGH   = { r = 1.00, g = 0.10, b = 0.10 },
    },

    ROLES = {
        TANK   = { r = 0.20, g = 0.60, b = 1.00 },
        HEALER = { r = 0.20, g = 1.00, b = 0.60 },
        DPS    = { r = 1.00, g = 0.40, b = 0.40 },
    },

    WARNING = {
        AGGRO_LOST    = { r = 1.00, g = 0.20, b = 0.20 },
        TAUNT         = { r = 1.00, g = 0.50, b = 0.10 },
        LOSING_AGGRO  = { r = 1.00, g = 0.80, b = 0.10 },
        PULLING_AGGRO = { r = 1.00, g = 0.80, b = 0.10 },
        AGGRO_PULLED  = { r = 1.00, g = 0.20, b = 0.20 },
        DROP_THREAT   = { r = 0.60, g = 0.60, b = 1.00 },
    },
}

------------------------------------------------------------
-- Utility: copy a color table
------------------------------------------------------------
function C:Copy(color)
    return { r = color.r, g = color.g, b = color.b }
end

------------------------------------------------------------
-- Utility: blend two colors (0–1)
------------------------------------------------------------
function C:Blend(a, b, t)
    return {
        r = a.r + (b.r - a.r) * t,
        g = a.g + (b.g - a.g) * t,
        b = a.b + (b.b - a.b) * t,
    }
end

------------------------------------------------------------
-- Utility: convert to hex
------------------------------------------------------------
function C:ToHex(color)
    return string.format("%02x%02x%02x",
        color.r * 255,
        color.g * 255,
        color.b * 255
    )
end

------------------------------------------------------------
-- Utility: convert from hex
------------------------------------------------------------
function C:FromHex(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber(hex:sub(1, 2), 16) / 255,
        g = tonumber(hex:sub(3, 4), 16) / 255,
        b = tonumber(hex:sub(5, 6), 16) / 255,
    }
end

------------------------------------------------------------
-- Profile-aware getters
------------------------------------------------------------
local function GetProfileColor(path, fallback)
    local node = TS.db and TS.db.profile and TS.db.profile.colors
    if not node then return fallback end

    for part in string.gmatch(path, "[^.]+") do
        node = node[part]
        if not node then return fallback end
    end

    return node
end

------------------------------------------------------------
-- Threat color based on percentage
------------------------------------------------------------
function C:GetThreatColor(pct)
    local profile = TS.db.profile.colors.threat

    if pct >= profile.highThreshold then
        return profile.high or self.DEFAULTS.THREAT.HIGH
    elseif pct >= profile.mediumThreshold then
        return profile.medium or self.DEFAULTS.THREAT.MEDIUM
    else
        return profile.low or self.DEFAULTS.THREAT.LOW
    end
end

------------------------------------------------------------
-- Role color
------------------------------------------------------------
function C:GetRoleColor(role)
    local profile = TS.db.profile.colors.roles
    return profile[role] or self.DEFAULTS.ROLES[role] or { r = 1, g = 1, b = 1 }
end

------------------------------------------------------------
-- Warning color
------------------------------------------------------------
function C:GetWarningColor(type)
    local profile = TS.db.profile.colors.warnings
    return profile[type] or self.DEFAULTS.WARNING[type] or { r = 1, g = 1, b = 1 }
end

------------------------------------------------------------
-- Initialize (future-proof)
------------------------------------------------------------
function C:Initialize()
    TS.Utils:Debug("Colors 2.0 initialized")
end

return C