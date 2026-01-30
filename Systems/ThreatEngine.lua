-- ThreatSense: ThreatEngine.lua
-- Core threat collection and tracking (event-driven, multi-unit aware)

local ADDON_NAME, TS = ...

TS.ThreatEngine = TS.ThreatEngine or {}
local Engine = TS.ThreatEngine

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
Engine.currentTarget = nil      -- unit id ("target" or "focus")
Engine.currentTargetName = nil  -- string
Engine.threatByUnit = {}        -- [unit] = threatData
Engine.threatList = {}          -- sorted list of threat entries

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function IsValidThreatTarget(unit)
    if not UnitExists(unit) then return false end
    if not UnitCanAttack("player", unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    return true
end

local function GetPrimaryTarget()
    if IsValidThreatTarget("target") then
        return "target"
    elseif IsValidThreatTarget("focus") then
        return "focus"
    end
    return nil
end

------------------------------------------------------------
-- Core update
------------------------------------------------------------
function Engine:Update()
    local target = GetPrimaryTarget()

    if not target then
        self:Reset()
        return
    end

    local targetName = UnitName(target)
    self.currentTarget = target
    self.currentTargetName = targetName

    self:UpdateThreatForTarget(target)
end

function Engine:UpdateThreatForTarget(target)
    if not TS.GroupManager or not TS.GroupManager.GetUnits then
        return
    end

    local units = TS.GroupManager:GetUnits()
    local threatByUnit = {}
    local threatList = {}

    local topThreat = 0
    local tankThreat = 0
    local playerThreat = 0
    local playerThreatPct = 0
    local playerIsTanking = false

    for _, unit in ipairs(units) do
        local threatData = TS.Utils:GetUnitThreat(unit, target)
        if threatData and threatData.threatValue > 0 then
            local name = UnitName(unit)
            local _, class = UnitClass(unit)

            local entry = {
                unit       = unit,
                name       = name,
                class      = class,
                threat     = threatData.threatValue,
                threatPct  = threatData.threatPct,
                isTanking  = threatData.isTanking,
            }

            threatByUnit[unit] = entry
            table.insert(threatList, entry)

            if threatData.threatValue > topThreat then
                topThreat = threatData.threatValue
            end

            if threatData.isTanking and threatData.threatValue > tankThreat then
                tankThreat = threatData.threatValue
            end

            if unit == "player" then
                playerThreat = threatData.threatValue
                playerThreatPct = threatData.threatPct
                playerIsTanking = threatData.isTanking
            end
        end
    end

    table.sort(threatList, function(a, b)
        return a.threat > b.threat
    end)

    self.threatByUnit = threatByUnit
    self.threatList = threatList
    self.topThreat = topThreat
    self.tankThreat = tankThreat
    self.playerThreat = playerThreat
    self.playerThreatPct = playerThreatPct
    self.playerIsTanking = playerIsTanking

    self:EmitThreatEvents()
end

------------------------------------------------------------
-- Event emission
------------------------------------------------------------
function Engine:EmitThreatEvents()
    if not TS.EventBus or not TS.EventBus.Send then
        return
    end

    TS.EventBus:Send("THREAT_TARGET_UPDATED", {
        unit = self.currentTarget,
        name = self.currentTargetName,
    })

    TS.EventBus:Send("THREAT_LIST_UPDATED", {
        list = self.threatList,
        topThreat = self.topThreat,
        tankThreat = self.tankThreat,
    })

    TS.EventBus:Send("PLAYER_THREAT_UPDATED", {
        threat = self.playerThreat,
        threatPct = self.playerThreatPct,
        isTanking = self.playerIsTanking,
    })
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function Engine:GetCurrentTarget()
    return self.currentTarget, self.currentTargetName
end

function Engine:GetThreatList()
    return self.threatList
end

function Engine:GetThreatForUnit(unit)
    return self.threatByUnit[unit]
end

function Engine:GetPlayerThreat()
    return self.playerThreat, self.playerThreatPct, self.playerIsTanking
end

------------------------------------------------------------
-- Reset state
------------------------------------------------------------
function Engine:Reset()
    self.currentTarget = nil
    self.currentTargetName = nil
    self.threatByUnit = {}
    self.threatList = {}
    self.topThreat = 0
    self.tankThreat = 0
    self.playerThreat = 0
    self.playerThreatPct = 0
    self.playerIsTanking = false

    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("THREAT_RESET")
    end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
local updateFrame

function Engine:Initialize()
    TS.Utils:Debug("ThreatEngine 2.0 initialized")

    if not updateFrame then
        updateFrame = CreateFrame("Frame")
        local elapsed = 0

        updateFrame:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta
            if elapsed >= TS.UPDATE_INTERVAL then
                elapsed = 0
                Engine:Update()
            end
        end)
    end
end