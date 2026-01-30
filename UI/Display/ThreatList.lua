-- ThreatSense: ThreatList.lua
-- Snapshot-driven, profile-based multi-bar threat list

local ADDON_NAME, TS = ...

TS.ThreatList = TS.ThreatList or {}
local List = TS.ThreatList

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
List.frame = nil
List.bars = {}

------------------------------------------------------------
-- Color mapping by threat category
------------------------------------------------------------
local CATEGORY_COLORS = {
    SAFE     = { r = 0.20, g = 0.80, b = 0.20 },
    WARNING  = { r = 0.90, g = 0.80, b = 0.20 },
    DANGER   = { r = 0.95, g = 0.50, b = 0.10 },
    CRITICAL = { r = 0.95, g = 0.20, b = 0.20 },
}

local function GetColorForCategory(category)
    return CATEGORY_COLORS[category] or CATEGORY_COLORS.SAFE
end

------------------------------------------------------------
-- Create a single bar
------------------------------------------------------------
local function CreateBar(parent, index)
    local profile = TS.db.profile.display

    local bar = CreateFrame("StatusBar", "ThreatSense_ThreatListBar"..index, parent)
    bar:SetMinMaxValues(0, 100)
    bar:SetHeight(profile.height)
    bar:SetWidth(profile.width)

    local spacing = profile.spacing or 4
    bar:SetPoint("TOP", 0, -((index - 1) * (profile.height + spacing)))

    bar:SetStatusBarTexture(TS.Media:Statusbar(profile.barTexture))

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.4)

    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(TS.Media:Font(profile.font), profile.fontSize, "OUTLINE")
    bar.text:SetPoint("LEFT", 4, 0)

    bar.role = bar:CreateTexture(nil, "OVERLAY")
    bar.role:SetSize(14, 14)
    bar.role:SetPoint("RIGHT", bar.text, "LEFT", -4, 0)
    bar.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
    bar.role:Hide()

    bar:Hide()
    return bar
end

------------------------------------------------------------
-- Apply profile settings to all bars
------------------------------------------------------------
function List:ApplyProfile()
    if not self.frame then return end

    local profile = TS.db.profile.display
    local max = profile.maxEntries

    local spacing = profile.spacing or 4
    local totalHeight = max * (profile.height + spacing)
    self.frame:SetSize(profile.width, totalHeight)

    if #self.bars ~= max then
        for _, bar in ipairs(self.bars) do bar:Hide() end
        self.bars = {}

        for i = 1, max do
            self.bars[i] = CreateBar(self.frame, i)
        end
    else
        for i, bar in ipairs(self.bars) do
            bar:SetHeight(profile.height)
            bar:SetWidth(profile.width)
            bar:SetStatusBarTexture(TS.Media:Statusbar(profile.barTexture))
            bar.text:SetFont(TS.Media:Font(profile.font), profile.fontSize, "OUTLINE")

            bar:ClearAllPoints()
            bar:SetPoint("TOP", 0, -((i - 1) * (profile.height + spacing)))
        end
    end
end

------------------------------------------------------------
-- Create the ThreatList frame
------------------------------------------------------------
function List:Create()
    if self.frame then return end

    local profile = TS.db.profile.display

    local frame = CreateFrame("Frame", "ThreatSense_ThreatList", UIParent)
    frame:SetPoint(profile.position.point, UIParent, profile.position.relativePoint, profile.position.x, profile.position.y)
    frame:Hide()

    self.frame = frame
    self.bars = {}

    self:ApplyProfile()

    --------------------------------------------------------
    -- Event listeners
    --------------------------------------------------------
    TS.EventBus:Register("THREAT_SNAPSHOT_UPDATED", function(snapshot)
        self:OnSnapshot(snapshot)
    end, {
        namespace = "ThreatList",
        source    = "ThreatList",
    })

    TS.EventBus:Register("THREAT_RESET", function()
        self:Hide()
    end, {
        namespace = "ThreatList",
        source    = "ThreatList",
    })

    TS.EventBus:Register("DISPLAY_MODE_CHANGED", function(mode)
        self:OnDisplayModeChanged(mode)
    end, {
        namespace = "ThreatList",
        source    = "ThreatList",
    })

    TS.EventBus:Register("PROFILE_CHANGED", function()
        self:ApplyProfile()
    end, {
        namespace = "ThreatList",
        source    = "ThreatList",
    })

    TS.Utils:Debug("ThreatList 2.0 (snapshot-driven) initialized")
end

------------------------------------------------------------
-- Display mode logic
------------------------------------------------------------
function List:OnDisplayModeChanged(mode)
    if mode == "LIST_ONLY" or mode == "BAR_AND_LIST" then
        self:Show()
    else
        self:Hide()
    end
end

------------------------------------------------------------
-- Snapshot handler
------------------------------------------------------------
function List:OnSnapshot(s)
    if not self.frame then return end

    local profile = TS.db.profile.display
    local max = profile.maxEntries
    local list = s.list or {}

    for i, bar in ipairs(self.bars) do
        local entry = list[i]

        if entry then
            local pct = entry.threatPct or 0
            local category = TS.ThreatMath:GetThreatCategory(pct)

            TS.Smoothing:Start(bar, pct)

            if profile.showText then
                bar.text:SetText(string.format("%s - %d%%", entry.name, pct))
            else
                bar.text:SetText("")
            end

            local c = GetColorForCategory(category)
            bar:SetStatusBarColor(c.r, c.g, c.b)

            if entry.isTanking then
                bar.role:Show()
                bar.role:SetTexCoord(0, 19/64, 22/64, 41/64)
            else
                bar.role:Hide()
            end

            bar:Show()
        else
            bar:Hide()
        end
    end

    self:Show()
end

------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------
function List:Show()
    if self.frame then self.frame:Show() end
end

function List:Hide()
    if self.frame then self.frame:Hide() end
end

return List