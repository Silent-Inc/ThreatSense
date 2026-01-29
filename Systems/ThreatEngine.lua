-- Modules/ThreatEngine.lua
-- Core threat calculation and tracking

local ADDON_NAME, TS = ...

TS.ThreatEngine = {}
local Engine = TS.ThreatEngine

Engine.currentThreat = {
    target = nil,
    playerThreat = 0,
    playerThreatPct = 0,
    isTanking = false,
    tankThreat = 0,
    topThreat = 0,
    relativePct = 0,
    threatList = {}
}

function Engine:Initialize()
    TS.Utils:Debug("ThreatEngine initialized")
end

function Engine:Update()
    self:UpdateTargetThreat()
end

function Engine:UpdateTargetThreat()
    local target = "target"

    if not UnitExists(target) or not UnitCanAttack("player", target) then
        self:ResetThreatData()
        return
    end

    local playerData = TS.Utils:GetUnitThreat("player", target)
    if not playerData then
        self:ResetThreatData()
        return
    end

    self.currentThreat.target = UnitName(target)
    self.currentThreat.playerThreat = playerData.threatValue
    self.currentThreat.playerThreatPct = playerData.threatPct
    self.currentThreat.isTanking = playerData.isTanking

    self:UpdateThreatList(target)
    self:CalculateRelativeThreat()
end

function Engine:UpdateThreatList(target)
    local threatList = {}
    local topThreat = 0
    local tankThreat = 0

    local isInGroup = IsInGroup()
    local isInRaid = IsInRaid()

    if isInGroup or isInRaid then
        local unitPrefix = isInRaid and "raid" or "party"
        local numMembers = isInRaid and GetNumGroupMembers() or GetNumSubgroupMembers()

        for i = 1, numMembers do
            local unit = unitPrefix .. i
            if UnitExists(unit) then
                local threatData = TS.Utils:GetUnitThreat(unit, target)
                if threatData then
                    local name = UnitName(unit)
                    local _, class = UnitClass(unit)

                    table.insert(threatList, {
                        name = name,
                        class = class,
                        unit = unit,
                        threat = threatData.threatValue,
                        threatPct = threatData.threatPct,
                        isTanking = threatData.isTanking
                    })

                    if threatData.threatValue > topThreat then
                        topThreat = threatData.threatValue
                    end

                    if threatData.isTanking and threatData.threatValue > tankThreat then
                        tankThreat = threatData.threatValue
                    end
                end
            end
        end
    else
        local playerData = TS.Utils:GetUnitThreat("player", target)
        if playerData then
            local name = UnitName("player")
            local _, class = UnitClass("player")

            table.insert(threatList, {
                name = name,
                class = class,
                unit = "player",
                threat = playerData.threatValue,
                threatPct = playerData.threatPct,
                isTanking = playerData.isTanking
            })

            tankThreat = playerData.threatValue
            topThreat = playerData.threatValue
        end
    end

    table.sort(threatList, function(a, b)
        return a.threat > b.threat
    end)

    self.currentThreat.threatList = threatList
    self.currentThreat.topThreat = topThreat
    self.currentThreat.tankThreat = tankThreat
end

function Engine:CalculateRelativeThreat()
    local playerRole = TS.Utils:GetPlayerRole()

    if playerRole == "TANK" and self.currentThreat.isTanking then
        if #self.currentThreat.threatList >= 2 then
            local secondThreat = self.currentThreat.threatList[2].threat
            if secondThreat > 0 then
                self.currentThreat.relativePct =
                    (self.currentThreat.playerThreat / secondThreat) * 100
            else
                self.currentThreat.relativePct = 0
            end
        else
            self.currentThreat.relativePct = 0
        end
    else
        local referenceThreat =
            (self.currentThreat.tankThreat > 0 and self.currentThreat.tankThreat)
            or self.currentThreat.topThreat

        if referenceThreat > 0 then
            self.currentThreat.relativePct =
                (self.currentThreat.playerThreat / referenceThreat) * 100
        else
            self.currentThreat.relativePct = 0
        end
    end
end

function Engine:ResetThreatData()
    self.currentThreat = {
        target = nil,
        playerThreat = 0,
        playerThreatPct = 0,
        isTanking = false,
        tankThreat = 0,
        topThreat = 0,
        relativePct = 0,
        threatList = {}
    }
end

function Engine:GetThreatData()
    return self.currentThreat
end

function Engine:GetMemberThreat(unit)
    for _, data in ipairs(self.currentThreat.threatList) do
        if data.unit == unit then
            return data
        end
    end
    return nil
end

return Engine