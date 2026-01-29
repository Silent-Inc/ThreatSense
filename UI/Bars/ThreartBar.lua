-- ThreatSense: ThreatBar.lua
-- Single-bar threat display

local ADDON_NAME, TS = ...
local ThreatBar = {}
TS.ThreatBar = ThreatBar

local TEXTURE = "Interface\\TARGETINGFRAME\\UI-StatusBar"

------------------------------------------------------------
-- Create the ThreatBar frame
------------------------------------------------------------
function ThreatBar:Create(parent)
    if self.frame then return end

    local frame = CreateFrame("StatusBar", ADDON_NAME.."ThreatBar", parent)
    frame:SetSize(220, 20)
    frame:SetPoint("CENTER")
    frame:SetStatusBarTexture(TEXTURE)
    frame:SetMinMaxValues(0, 100)
    frame:Hide()

    self.frame = frame

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.4)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("CENTER")

    ------------------------------------------------------------
    -- Listen for threat updates
    ------------------------------------------------------------
    TS.EventBus:Register("THREAT_UPDATED", function(data)
        self:Update(data)
    end)

    ------------------------------------------------------------
    -- React to display mode changes
    ------------------------------------------------------------
    TS.EventBus:Register("DISPLAY_MODE_CHANGED", function(mode)
        if mode == "BAR_ONLY" or mode == "BAR_AND_LIST" then
            self:Show()
        else
            self:Hide()
        end
    end)
end

------------------------------------------------------------
-- Update the bar with threat data
------------------------------------------------------------
function ThreatBar:Update(data)
    if not self.frame then return end

    local pct = data.playerThreatPct or 0
    local target = data.target or "No Target"

    -- Smooth animation
    TS.Smoothing:Start(self.frame, pct)

    -- Text
    self.frame.text:SetText(string.format("%s - %d%%", target, pct))

    -- Color logic (simple for now, will expand later)
    if pct >= 90 then
        self.frame:SetStatusBarColor(1, 0, 0)       -- red
    elseif pct >= 70 then
        self.frame:SetStatusBarColor(1, 0.5, 0)     -- orange
    else
        self.frame:SetStatusBarColor(0, 1, 0)       -- green
    end

    self.frame:Show()
end

------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------
function ThreatBar:Show()
    if self.frame then self.frame:Show() end
end

function ThreatBar:Hide()
    if self.frame then self.frame:Hide() end
end