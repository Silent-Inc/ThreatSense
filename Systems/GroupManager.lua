-- ThreatSense: GroupManager.lua
-- Centralized group unit management and caching

local ADDON_NAME, TS = ...

TS.GroupManager = TS.GroupManager or {}
local Group = TS.GroupManager

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
Group.units = {}
Group.isInGroup = false
Group.isInRaid = false

------------------------------------------------------------
-- Build the current unit list
-- Includes player, party/raid, and pets.
------------------------------------------------------------
function Group:RefreshUnits()
    local units = {}

    -- Always include player
    table.insert(units, "player")

    local inGroup = IsInGroup()
    local inRaid = IsInRaid()

    Group.isInGroup = inGroup or inRaid
    Group.isInRaid = inRaid

    if inRaid then
        local num = GetNumGroupMembers()
        for i = 1, num do
            local unit = "raid" .. i
            if UnitExists(unit) then
                table.insert(units, unit)
                local pet = "raidpet" .. i
                if UnitExists(pet) then
                    table.insert(units, pet)
                end
            end
        end
    elseif inGroup then
        local num = GetNumSubgroupMembers()
        for i = 1, num do
            local unit = "party" .. i
            if UnitExists(unit) then
                table.insert(units, unit)
                local pet = "partypet" .. i
                if UnitExists(pet) then
                    table.insert(units, pet)
                end
            end
        end

        -- Player pet in party
        if UnitExists("pet") then
            table.insert(units, "pet")
        end
    else
        -- Solo: include player pet if present
        if UnitExists("pet") then
            table.insert(units, "pet")
        end
    end

    Group.units = units

    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("GROUP_UNITS_UPDATED", units)
    end
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function Group:GetUnits()
    return self.units
end

function Group:IsInGroup()
    return self.isInGroup
end

function Group:IsInRaid()
    return self.isInRaid
end

------------------------------------------------------------
-- Event handling
------------------------------------------------------------
local eventFrame

function Group:Initialize()
    if eventFrame then return end

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            Group:RefreshUnits()
        end
    end)

    -- Initial population
    self:RefreshUnits()
end