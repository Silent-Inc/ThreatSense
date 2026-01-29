-- Modules/Config_Warnings.lua
-- ThreatSense Warnings Settings Panel (modern Settings API)

local ADDON_NAME, TS = ...

TS.ConfigWarnings = {}
local ConfigWarnings = TS.ConfigWarnings

local panel
local previewFrame -- declared here, created inside Initialize()

---------------------------------------------------------
-- Sound List
---------------------------------------------------------

local SOUND_LIST = {
    { name = "Raid Warning", id = SOUNDKIT.RAID_WARNING },
    { name = "Alarm",        id = SOUNDKIT.ALARM_CLOCK_WARNING_3 },
    { name = "Bell",         id = SOUNDKIT.BELL_TOLL_ALLIANCE },
    { name = "Horn",         id = SOUNDKIT.READY_CHECK },
    { name = "Whistle",      id = SOUNDKIT.PVP_FLAG_TAKEN },
    { name = "Error",        id = SOUNDKIT.ERROR },
}

---------------------------------------------------------
-- Initialize Warnings Panel
---------------------------------------------------------

function ConfigWarnings:Initialize()
    panel = CreateFrame("Frame")
    panel.name = "Warnings"
    panel.parent = "ThreatSense"

    -----------------------------------------------------
    -- Title
    -----------------------------------------------------
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThreatSense – Warnings")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure audio and visual threat warnings.")

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
            ConfigWarnings:UpdatePreview()
        end)
        return cb
    end

    -----------------------------------------------------
    -- Helper: Slider
    -----------------------------------------------------
    local function CreateSlider(label, minVal, maxVal, step, x, y, initial, callback)
        local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", x, y)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(initial)

        slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        slider.Text:SetPoint("BOTTOM", slider, "TOP", 0, 4)
        slider.Text:SetText(label)

        slider.Low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
        slider.Low:SetText(minVal)

        slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
        slider.High:SetText(maxVal)

        slider:SetScript("OnValueChanged", function(self, value)
            callback(value)
            ConfigWarnings:UpdatePreview()
        end)

        return slider
    end

    -----------------------------------------------------
    -- Checkboxes
    -----------------------------------------------------

    CreateCheckbox(
        "Enable Warnings",
        "Enable or disable all threat warnings.",
        16, -60,
        TS.db.profile.warnings.enabled,
        function(val)
            TS.db.profile.warnings.enabled = val
        end
    )

    CreateCheckbox(
        "Enable Sound Warnings",
        "Play audio warnings when threat is high.",
        16, -90,
        TS.db.profile.warnings.soundEnabled,
        function(val)
            TS.db.profile.warnings.soundEnabled = val
        end
    )

    CreateCheckbox(
        "Enable Visual Warnings",
        "Show on-screen warnings when threat is high.",
        16, -120,
        TS.db.profile.warnings.visualEnabled,
        function(val)
            TS.db.profile.warnings.visualEnabled = val
        end
    )

    -----------------------------------------------------
    -- Sliders
    -----------------------------------------------------

    CreateSlider(
        "Warning Threshold (%)",
        50, 100, 1,
        300, -60,
        TS.db.profile.warnings.warningThreshold,
        function(val)
            TS.db.profile.warnings.warningThreshold = val
        end
    )

    CreateSlider(
        "Danger Threshold (%)",
        60, 100, 1,
        300, -120,
        TS.db.profile.warnings.dangerThreshold,
        function(val)
            TS.db.profile.warnings.dangerThreshold = val
        end
    )

    -----------------------------------------------------
    -- Sound Dropdown
    -----------------------------------------------------

    local function CreateDropdown(label, items, x, y, initialIndex, callback)
        local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", x, y)

        local labelText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 0)
        labelText:SetText(label)

        UIDropDownMenu_SetWidth(dropdown, 160)
        UIDropDownMenu_SetSelectedID(dropdown, initialIndex)

        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for i, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.name
                info.func = function()
                    UIDropDownMenu_SetSelectedID(dropdown, i)
                    callback(i, item)
                    ConfigWarnings:UpdatePreview()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        return dropdown
    end

    -- Determine initial sound index
    local initialSoundIndex = 1
    for i, snd in ipairs(SOUND_LIST) do
        if snd.id == TS.db.profile.warnings.soundFile then
            initialSoundIndex = i
        end
    end

    CreateDropdown(
        "Warning Sound",
        SOUND_LIST,
        16, -200,
        initialSoundIndex,
        function(index, item)
            TS.db.profile.warnings.soundFile = item.id
            PlaySound(item.id, "Master")
        end
    )

    -----------------------------------------------------
    -- PREVIEW WINDOW
    -----------------------------------------------------

    previewFrame = CreateFrame("Frame", "ThreatSenseWarningsPreviewFrame", panel, "BackdropTemplate")
    previewFrame:SetPoint("TOPLEFT", 16, -260)
    previewFrame:SetSize(350, 100)
    previewFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    previewFrame:SetBackdropColor(0, 0, 0, 0.6)
    previewFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local previewTitle = previewFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    previewTitle:SetPoint("TOPLEFT", 10, -10)
    previewTitle:SetText("Preview")

    previewFrame.warningText = previewFrame:CreateFontString(nil, "OVERLAY")
    previewFrame.warningText:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    previewFrame.warningText:SetPoint("CENTER")
    previewFrame.warningText:SetText("")

    -----------------------------------------------------
    -- Initial preview update
    -----------------------------------------------------
    ConfigWarnings:UpdatePreview()

	-----------------------------------------------------
	-- REGISTER PANEL
	-----------------------------------------------------
	local function RegisterDisplayCategory()
		local parent = Settings.GetCategory("ThreatSenseRoot")
		if not parent then
			return -- parent not ready yet
		end

		local category = Settings.RegisterCanvasLayoutCategory(panel, "Warnings")
		category.parent = parent
		Settings.RegisterAddOnCategory(category)

		print("ThreatSense: Warnings category registered")
	end

	-----------------------------------------------------
	-- Register when Settings UI is ready
	-----------------------------------------------------
	local f = CreateFrame("Frame")
		f:RegisterEvent("SETTINGS_LOADED")
		f:SetScript("OnEvent", RegisterDisplayCategory)
	end

---------------------------------------------------------
-- Preview Update
---------------------------------------------------------

function ConfigWarnings:UpdatePreview()
    if not previewFrame then return end

    previewFrame.warningText:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")

    if not TS.db.profile.warnings.enabled then
        previewFrame.warningText:SetText("|cFF888888Warnings Disabled|r")
        return
    end

    previewFrame.warningText:SetText(
        "|cFFFFFF00Warning Threshold: "
        .. TS.db.profile.warnings.warningThreshold .. "%|r"
    )
end

---------------------------------------------------------
-- Test Warning
---------------------------------------------------------

function ConfigWarnings:ShowTestWarning()
    if not previewFrame then return end

    local pct = TS.db.profile.warnings.dangerThreshold

    previewFrame.warningText:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    previewFrame.warningText:SetText(
        string.format("|cFFFFA500HIGH THREAT! (%.0f%%)|r", pct)
    )
end

return ConfigWarnings