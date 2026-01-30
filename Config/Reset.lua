-- ThreatSense: Reset.lua
-- Modern profile reset (AceDB, ProfileManager 2.0, role-aware defaults)

local ADDON_NAME, TS = ...
local Reset = {}
TS.Reset = Reset

local PM = TS.ProfileManager
local RM = TS.RoleManager

------------------------------------------------------------
-- Role-aware default profiles (structured for TS.db.profile)
------------------------------------------------------------
local ROLE_DEFAULTS = {
    TANK = {
        display = {
            mode = "BAR_AND_LIST",
            barTexture = "",
            backgroundTexture = "",
            font = "",
            fontSize = 12,
            barHeight = 18,
            barSpacing = 2,
            rowHeight = 16,
            rowSpacing = 1,
            smoothSpeed = 0.2,
            combatFade = false,
            combatFadeOpacity = 0.4,
            threatGradient = true,
        },
        warnings = {
            enabled = true,
            style = "ICON",
            warnTaunt = true,
            warnLosingAggro = true,
            warnAggroLost = true,
            warnPullingAggro = true,
            warnAggroPulled = true,
            warnDropThreat = true,
            tankLosingAggroThreshold = 80,
            dpsPullingAggroThreshold = 90,
            dpsDropThreatThreshold = 95,
            healerPullingAggroThreshold = 90,
            iconSize = 64,
            sound = "",
            soundVolume = 1,
        },
        colors = {
            warnings = {
                AGGRO_LOST = { r = 1, g = 0.2, b = 0.2, a = 1 },
                TAUNT = { r = 1, g = 0.5, b = 0.1, a = 1 },
                LOSING_AGGRO = { r = 1, g = 0.8, b = 0.1, a = 1 },
                PULLING_AGGRO = { r = 1, g = 0.8, b = 0.1, a = 1 },
                AGGRO_PULLED = { r = 1, g = 0.2, b = 0.2, a = 1 },
            }
        }
    },

    HEALER = {
        display = {
            mode = "LIST_ONLY",
            barTexture = "",
            backgroundTexture = "",
            font = "",
            fontSize = 12,
            barHeight = 18,
            barSpacing = 2,
            rowHeight = 16,
            rowSpacing = 1,
            smoothSpeed = 0.2,
            combatFade = false,
            combatFadeOpacity = 0.4,
            threatGradient = true,
        },
        warnings = {
            enabled = true,
            style = "TEXT",
            warnTaunt = false,
            warnLosingAggro = false,
            warnAggroLost = false,
            warnPullingAggro = true,
            warnAggroPulled = false,
            warnDropThreat = false,
            tankLosingAggroThreshold = 80,
            dpsPullingAggroThreshold = 90,
            dpsDropThreatThreshold = 95,
            healerPullingAggroThreshold = 90,
            iconSize = 64,
            sound = "",
            soundVolume = 1,
        },
        colors = {
            warnings = {
                AGGRO_LOST = { r = 1, g = 0.2, b = 0.2, a = 1 },
                TAUNT = { r = 1, g = 0.5, b = 0.1, a = 1 },
                LOSING_AGGRO = { r = 1, g = 0.8, b = 0.1, a = 1 },
                PULLING_AGGRO = { r = 1, g = 0.8, b = 0.1, a = 1 },
                AGGRO_PULLED = { r = 1, g = 0.2, b = 0.2, a = 1 },
            }
        }
    },

    DPS = {
        display = {
            mode = "BAR_ONLY",
            barTexture = "",
            backgroundTexture = "",
            font = "",
            fontSize = 12,
            barHeight = 18,
            barSpacing = 2,
            rowHeight = 16,
            rowSpacing = 1,
            smoothSpeed = 0.2,
            combatFade = false,
            combatFadeOpacity = 0.4,
            threatGradient = true,
        },
        warnings = {
            enabled = true,
            style = "ICON",
            warnTaunt = false,
            warnLosingAggro = false,
            warnAggroLost = false,
            warnPullingAggro = true,
            warnAggroPulled = true,
            warnDropThreat = true,
            tankLosingAggroThreshold = 80,
            dpsPullingAggroThreshold = 90,
            dpsDropThreatThreshold = 95,
            healerPullingAggroThreshold = 90,
            iconSize = 64,
            sound = "",
            soundVolume = 1,
        },
        colors = {
            warnings = {
                AGGRO_LOST = { r = 1, g = 0.2, b = 0.2, a = 1 },
                TAUNT = { r = 1, g = 0.5, b = 0.1, a = 1 },
                LOSING_AGGRO = { r = 1, g = 0.8, b = 0.1, a = 1 },
                PULLING_AGGRO = { r = 1, g = 0.8, b = 0.1, a = 1 },
                AGGRO_PULLED = { r = 1, g = 0.2, b = 0.2, a = 1 },
            }
        }
    }
}

------------------------------------------------------------
-- Apply role defaults into the active profile
------------------------------------------------------------
local function ApplyRoleDefaults()
    local role = RM:GetCurrentRole() or "DPS"
    local defaults = ROLE_DEFAULTS[role]
    if not defaults then return end

    local profile = TS.db.profile

    -- Deep copy defaults into profile
    for section, values in pairs(defaults) do
        profile[section] = profile[section] or {}
        for key, value in pairs(values) do
            profile[section][key] = value
        end
    end
end

------------------------------------------------------------
-- Reset active profile
------------------------------------------------------------
local function ResetActiveProfile()
    TS.db:ResetProfile()      -- AceDB reset
    ApplyRoleDefaults()       -- Apply role defaults

    TS.EventBus:Send("PROFILE_RESET")
    TS.EventBus:Send("PROFILE_CHANGED")

    if TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Stop()
    end
    if TS.WarningPreview:IsActive() then
        TS.WarningPreview:Stop()
    end
end

------------------------------------------------------------
-- Initialize Reset Panel
------------------------------------------------------------
function Reset:Initialize()
    local categoryName = TS.Categories.RESET or "ThreatSense - Reset"
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    Settings.CreateControlButton(
        layout,
        "Reset Active Profile",
        "Reset all settings in the active profile and reapply role-based defaults.",
        function()
            ResetActiveProfile()
        end
    )

    Settings.RegisterAddOnCategory(category)
end

return Reset