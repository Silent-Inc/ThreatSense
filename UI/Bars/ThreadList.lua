local addonName, TS = ...
local ThreatList = {}
TS.ThreatList = ThreatList

-- Constants
local BAR_HEIGHT = 18
local BAR_SPACING = 4
local MAX_BARS = 8
local TEXTURE = "Interface\\TARGETINGFRAME\\UI-StatusBar"

local classColors = RAID_CLASS_COLORS

------------------------------------------------------------
-- Create the ThreatList frame and bars
------------------------------------------------------------
function ThreatList:Create(parent)
    if self.frame then return end

    local frame = CreateFrame("Frame", addonName.."ThreatList", parent)
    frame:SetSize(200, (BAR_HEIGHT + BAR_SPACING) * MAX_BARS)
    frame:SetPoint("CENTER")
    frame:Hide()

    self.frame = frame
    self.bars = {}

    for i = 1, MAX_BARS do
        local bar = CreateFrame("StatusBar", nil, frame)
        bar:SetSize(200, BAR_HEIGHT)
        bar:SetPoint("TOP", 0, -((i - 1) * (BAR_HEIGHT + BAR_SPACING)))
        bar:SetStatusBarTexture(TEXTURE)
        bar:SetMinMaxValues(0, 100)
        bar:Hide()

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints()
        bar.bg:SetColorTexture(0, 0, 0, 0.4)

        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bar.text:SetPoint("LEFT", 4, 0)

		bar.role = bar:CreateTexture(nil, "OVERLAY")
		bar.role:SetSize(14, 14)
		bar.role:SetPoint("RIGHT", bar.text, "LEFT", -4, 0)
		bar.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
		bar.role:Hide()

        self.bars[i] = bar
    end

    -- Register for threat updates
    TS.EventBus:Register("THREAT_UPDATED", function(data)
        self:Update(data)
    end)
end

------------------------------------------------------------
-- Update the bars with threat data
------------------------------------------------------------
function ThreatList:Update(threatData)
    if not self.frame then return end

    -- Sort by threat descending
    table.sort(threatData, function(a, b)
        return a.threat > b.threat
    end)

    for i, bar in ipairs(self.bars) do
        local entry = threatData[i]

        if entry then
            local color = classColors[entry.class] or { r = 1, g = 1, b = 1 }

            TS.Smoothing:Start(bar, entry.threat)
            bar:SetStatusBarColor(color.r, color.g, color.b)
            bar.text:SetText(string.format("%s - %d%%", entry.name, entry.threatPct or entry.threat))

			if entry.isTanking then
				bar.role:Show()
				bar.role:SetTexCoord(0, 19/64, 22/64, 41/64) -- tank icon
			else
				bar.role:Hide()
			end
            bar:Show()
        else
            bar:Hide()
        end
    end

    self.frame:Show()
end

------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------
function ThreatList:Show()
    if self.frame then self.frame:Show() end
end

function ThreatList:Hide()
    if self.frame then self.frame:Hide() end
end
