-- ThreatSense: Smoothing.lua
-- Threat smoothing, lerp, history tracking

local ADDON_NAME, TS = ...

TS.Smoothing = {}

function TS.Smoothing:Lerp(a, b, t)
    return a + (b - a) * t
end