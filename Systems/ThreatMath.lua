-- ThreatSense: ThreatMath.lua
-- Pure math helpers for threat calculations (no UI, no profile access)

local ADDON_NAME, TS = ...
TS.ThreatMath = TS.ThreatMath or {}
local Math = TS.ThreatMath

------------------------------------------------------------
-- Basic helpers
------------------------------------------------------------
local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

local function pct(a, b)
    if not a or not b or b <= 0 then
        return 0
    end
    return (a / b) * 100
end

------------------------------------------------------------
-- Relative threat calculations
------------------------------------------------------------
-- Threat % relative to tank (for DPS/Healer)
function Math:GetRelativeThreat(playerThreat, tankThreat)
    return clamp(pct(playerThreat, tankThreat), 0, 999)
end

-- Tank threat % relative to second-highest
function Math:GetTankRelativeThreat(tankThreat, secondThreat)
    return clamp(pct(tankThreat, secondThreat), 0, 999)
end

------------------------------------------------------------
-- Threat deltas and velocity
------------------------------------------------------------
-- Absolute difference in threat
function Math:GetThreatDelta(a, b)
    if not a or not b then return 0 end
    return a - b
end

-- Threat velocity (rate of change)
function Math:GetThreatVelocity(prevThreat, currentThreat, deltaTime)
    if not prevThreat or not currentThreat or not deltaTime or deltaTime <= 0 then
        return 0
    end
    return (currentThreat - prevThreat) / deltaTime
end

------------------------------------------------------------
-- Role-aware threat logic
------------------------------------------------------------
-- Is a DPS pulling aggro?
function Math:IsPullingAggro(playerThreat, tankThreat, thresholdPct)
    local rel = self:GetRelativeThreat(playerThreat, tankThreat)
    return rel >= thresholdPct, rel
end

-- Is a tank losing aggro?
function Math:IsLosingAggro(tankThreat, secondThreat, thresholdPct)
    local rel = self:GetTankRelativeThreat(tankThreat, secondThreat)
    return rel <= thresholdPct, rel
end

-- Has the tank lost aggro?
function Math:HasLostAggro(tankThreat, secondThreat)
    return secondThreat > tankThreat
end

-- Has a DPS pulled aggro?
function Math:HasPulledAggro(playerThreat, tankThreat)
    return playerThreat > tankThreat
end

------------------------------------------------------------
-- Threat prediction (simple linear)
------------------------------------------------------------
function Math:PredictThreat(currentThreat, velocity, timeAhead)
    if not currentThreat or not velocity or not timeAhead then
        return currentThreat or 0
    end
    return currentThreat + (velocity * timeAhead)
end

------------------------------------------------------------
-- Multi-target helpers
------------------------------------------------------------
-- Returns the highest threat and second-highest threat from a table
function Math:GetTopTwoThreats(threatTable)
    local highest = 0
    local second = 0

    for _, threat in pairs(threatTable) do
        if threat > highest then
            second = highest
            highest = threat
        elseif threat > second then
            second = threat
        end
    end

    return highest, second
end

-- Returns sorted threat list (descending)
function Math:SortThreatList(threatTable)
    local list = {}
    for unit, threat in pairs(threatTable) do
        table.insert(list, { unit = unit, threat = threat })
    end
    table.sort(list, function(a, b) return a.threat > b.threat end)
    return list
end

------------------------------------------------------------
-- Threat color logic (pure math, no profile)
-- UI modules map these categories to actual colors.
------------------------------------------------------------
function Math:GetThreatCategory(threatPct)
    if threatPct < 60 then
        return "SAFE"
    elseif threatPct < 80 then
        return "WARNING"
    elseif threatPct < 100 then
        return "DANGER"
    else
        return "CRITICAL"
    end
end

return Math