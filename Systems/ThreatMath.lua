-- ThreatSense: ThreatMath.lua
-- Pure math helpers for threat calculations

local ADDON_NAME, TS = ...

TS.ThreatMath = TS.ThreatMath or {}
local Math = TS.ThreatMath

------------------------------------------------------------
-- Relative threat vs reference
------------------------------------------------------------
function Math:GetRelativeThreat(playerThreat, referenceThreat)
    if not playerThreat or not referenceThreat or referenceThreat <= 0 then
        return 0
    end
    return (playerThreat / referenceThreat) * 100
end

------------------------------------------------------------
-- Tank relative threat vs second highest
------------------------------------------------------------
function Math:GetTankRelativeThreat(playerThreat, secondThreat)
    if not playerThreat or not secondThreat or secondThreat <= 0 then
        return 0
    end
    return (playerThreat / secondThreat) * 100
end

------------------------------------------------------------
-- Get color for threat percentage using profile or fallback
------------------------------------------------------------
function Math:GetColorForThreat(threatPct, profile)
    -- If profile defines custom colors, use them
    if profile and profile.colors and profile.colors.threat then
        local c = profile.colors.threat
        -- Expecting something like { safe = {r,g,b}, warning = ..., ... }
        if threatPct < TS.THREAT_THRESHOLDS.SAFE and c.safe then
            return c.safe.r, c.safe.g, c.safe.b
        elseif threatPct < TS.THREAT_THRESHOLDS.WARNING and c.warning then
            return c.warning.r, c.warning.g, c.warning.b
        elseif threatPct < TS.THREAT_THRESHOLDS.DANGER and c.danger then
            return c.danger.r, c.danger.g, c.danger.b
        elseif c.critical then
            return c.critical.r, c.critical.g, c.critical.b
        end
    end

    -- Fallback to global constants
    return TS.Utils:GetThreatColor(threatPct)
end