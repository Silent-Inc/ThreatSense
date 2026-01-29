-- Modules/Config.lua
-- Main ThreatSense panel (modern Settings API)

local ADDON_NAME, TS = ...

TS.Config = {}
local Config = TS.Config

local panel

function Config:Initialize()
    panel = CreateFrame("Frame")
    panel.name = "ThreatSense"

    -----------------------------------------------------
    -- Title
    -----------------------------------------------------
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThreatSense")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("General addon settings.")

    -----------------------------------------------------
    -- Version
    -----------------------------------------------------
    local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    versionText:SetPoint("TOPRIGHT", -16, -16)
    versionText:SetText("Version: " .. (TS.VERSION or "Unknown"))

	-----------------------------------------------------
	-- DISPLAY MODE DROPDOWN
	-----------------------------------------------------
	local function CreateDisplayModeSetting(panel)
		local variable = "displayMode"
		local defaultValue = "single"   -- fallback default

		-- Register the setting
		local setting = Settings.RegisterAddOnSetting(
			"ThreatSenseRoot",
			variable,
			"string",
			defaultValue
		)

		-- Create dropdown
		local options = {
			{ value = "single",      label = "Single bar only" },
			{ value = "both",        label = "Single bar + list" },
			{ value = "list",        label = "List only (no main bar)" },
		}

		Settings.CreateDropdown(
			panel,
			setting,
			"Display Mode",
			"Choose how ThreatSense displays threat information.",
			options
		)
	end

    -----------------------------------------------------
    -- Helper: Checkbox
    -----------------------------------------------------
    local function CreateCheckbox(label, tooltip, x, y, initial, callback)
        local cb = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb.Text:SetText(label)
        cb.tooltipText = tooltip
        cb:SetChecked(initial)
        cb:SetScript("OnClick", function(self)
            callback(self:GetChecked())
        end)
        return cb
    end

    -----------------------------------------------------
    -- Checkboxes
    -----------------------------------------------------
    CreateCheckbox(
        "Enable ThreatSense",
        "Enable or disable the addon.",
        16, -60,
        TS.db.profile.enabled,
        function(val)
            TS.db.profile.enabled = val
            if val then TS:StartUpdates() else TS:StopUpdates() end
        end
    )

    CreateCheckbox(
        "Lock Display",
        "Prevents moving the display frame.",
        16, -90,
        TS.db.profile.locked,
        function(val)
            TS.db.profile.locked = val
            if TS.Display then TS.Display:SetLocked(val) end
        end
    )

    CreateCheckbox(
        "Debug Mode",
        "Prints debug information to chat.",
        16, -120,
        TS.db.profile.debug,
        function(val)
            TS.db.profile.debug = val
        end
    )

	-----------------------------------------------------
	-- Add display mode dropdown
	-----------------------------------------------------
	function Config:Initialize()
		panel = CreateFrame("Frame")
		panel.name = "ThreatSense"

		local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText("ThreatSense")

		local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
		subtitle:SetText("General addon settings and configuration.")

		-----------------------------------------------------
		-- Add display mode dropdown
		-----------------------------------------------------
		CreateDisplayModeSetting(panel)

		-----------------------------------------------------
		-- Register parent category
		-----------------------------------------------------
		if Settings and Settings.RegisterCanvasLayoutCategory then
			local category = Settings.RegisterCanvasLayoutCategory(panel, "ThreatSense")
			category.ID = "ThreatSenseRoot"
			Settings.RegisterAddOnCategory(category)
		end
	end

    -----------------------------------------------------
    -- Reset Position Button
    -----------------------------------------------------
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 16, -160)
    resetButton:SetSize(140, 24)
    resetButton:SetText("Reset Position")
    resetButton:SetScript("OnClick", function()
        TS.db.profile.position = TS.Utils:CopyTable(TS.DEFAULT_POSITION)
        if TS.Display then TS.Display:ResetPosition() end
        TS.Utils:Print("ThreatSense position reset.")
    end)

    -----------------------------------------------------
    -- Reload UI Button
    -----------------------------------------------------
    local reloadButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -10)
    reloadButton:SetSize(140, 24)
    reloadButton:SetText("Reload UI")
    reloadButton:SetScript("OnClick", ReloadUI)

    -----------------------------------------------------
    -- REGISTER PARENT CATEGORY (modern Settings API)
    -----------------------------------------------------
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ThreatSense")
        category.ID = "ThreatSenseRoot"
        Settings.RegisterAddOnCategory(category)

        -- Optional debug
        -- print("ThreatSense: Parent category registered")
    end
end

return Config