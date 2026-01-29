-- Modules/Config_Display.lua
-- ThreatSense Display Settings Panel (modern Settings API)

local ADDON_NAME, TS = ...

TS.ConfigDisplay = {}
local ConfigDisplay = TS.ConfigDisplay

local panel
local previewFrame
local previewRows = {}

local ROW_HEIGHT = 14
local ROW_SPACING = 2

---------------------------------------------------------
-- Texture List
---------------------------------------------------------

local TEXTURE_LIST = {
    { name = "Blizzard", file = "Interface\\TargetingFrame\\UI-StatusBar" },
    { name = "Smooth",   file = "Interface\\AddOns\\ThreatSense\\Media\\smooth" },
    { name = "Minimal",  file = "Interface\\AddOns\\ThreatSense\\Media\\minimal" },
    { name = "Striped",  file = "Interface\\AddOns\\ThreatSense\\Media\\striped" },
    { name = "Gradient", file = "Interface\\AddOns\\ThreatSense\\Media\\gradient" },
}

---------------------------------------------------------
-- Font List
---------------------------------------------------------

local FONT_LIST = {
    { name = "Friz Quadrata", file = "Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow",  file = "Fonts\\ARIALN.TTF" },
    { name = "Morpheus",      file = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri",        file = "Fonts\\SKURRI.TTF" },
    { name = "Standard",      file = STANDARD_TEXT_FONT },
}

---------------------------------------------------------
-- Initialize Display Panel
---------------------------------------------------------

function ConfigDisplay:Initialize()
	panel = CreateFrame("Frame")
    panel.name = "Display"
    panel.parent = "ThreatSense"

    -----------------------------------------------------
    -- Title
    -----------------------------------------------------
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ThreatSense – Display")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Customize the appearance of the ThreatSense display.")

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
            ConfigDisplay:UpdatePreview()
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
            ConfigDisplay:UpdatePreview()
        end)

        return slider
    end

    -----------------------------------------------------
    -- Helper: Dropdown
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
                    ConfigDisplay:UpdatePreview()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        return dropdown
    end

    -----------------------------------------------------
    -- Checkboxes
    -----------------------------------------------------

    CreateCheckbox(
        "Show Text",
        "Show the target name and threat percentage on the main bar.",
        16, -60,
        TS.db.profile.display.showText,
        function(val)
            TS.db.profile.display.showText = val
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    CreateCheckbox(
        "Show Percentage",
        "Show threat percentage values on bars.",
        16, -90,
        TS.db.profile.display.showPercentage,
        function(val)
            TS.db.profile.display.showPercentage = val
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    CreateCheckbox(
        "Show Only In Combat",
        "Hide the display when not in combat.",
        16, -120,
        TS.db.profile.display.showInCombatOnly,
        function(val)
            TS.db.profile.display.showInCombatOnly = val
        end
    )

    -----------------------------------------------------
    -- Sliders
    -----------------------------------------------------

    CreateSlider(
        "Bar Width",
        100, 400, 10,
        300, -60,
        TS.db.profile.display.width,
        function(val)
            TS.db.profile.display.width = val
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    CreateSlider(
        "Bar Height",
        10, 40, 1,
        300, -120,
        TS.db.profile.display.height,
        function(val)
            TS.db.profile.display.height = val
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    CreateSlider(
        "Scale",
        0.5, 2.0, 0.05,
        300, -180,
        TS.db.profile.display.scale,
        function(val)
            TS.db.profile.display.scale = val
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    CreateSlider(
        "Max Threat List Entries",
        1, 10, 1,
        300, -240,
        TS.db.profile.display.maxEntries,
        function(val)
            TS.db.profile.display.maxEntries = val
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    -----------------------------------------------------
    -- Texture Dropdown
    -----------------------------------------------------

    local initialTextureIndex = 1
    for i, tex in ipairs(TEXTURE_LIST) do
        if tex.file == TS.db.profile.display.barTexture then
            initialTextureIndex = i
        end
    end

    CreateDropdown(
        "Bar Texture",
        TEXTURE_LIST,
        16, -180,
        initialTextureIndex,
        function(index, item)
            TS.db.profile.display.barTexture = item.file
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    -----------------------------------------------------
    -- Font Dropdown
    -----------------------------------------------------

    local initialFontIndex = 1
    for i, font in ipairs(FONT_LIST) do
        if font.file == TS.db.profile.display.font then
            initialFontIndex = i
        end
    end

    CreateDropdown(
        "Font",
        FONT_LIST,
        16, -240,
        initialFontIndex,
        function(index, item)
            TS.db.profile.display.font = item.file
            if TS.Display then TS.Display:ApplySettings() end
        end
    )

    -----------------------------------------------------
    -- PREVIEW WINDOW
    -----------------------------------------------------

    previewFrame = CreateFrame("Frame", "ThreatSenseDisplayPreviewFrame", panel, "BackdropTemplate")
    previewFrame:SetPoint("TOPLEFT", 16, -320)
    previewFrame:SetSize(350, 200)
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

    -----------------------------------------------------
    -- Main preview bar
    -----------------------------------------------------

    previewFrame.mainBar = CreateFrame("StatusBar", nil, previewFrame)
    previewFrame.mainBar:SetPoint("TOPLEFT", 10, -40)
    previewFrame.mainBar:SetPoint("TOPRIGHT", -10, -40)
    previewFrame.mainBar:SetHeight(20)
    previewFrame.mainBar:SetMinMaxValues(0, 100)
    previewFrame.mainBar:SetValue(65)

    previewFrame.mainText = previewFrame.mainBar:CreateFontString(nil, "OVERLAY")
    previewFrame.mainText:SetPoint("CENTER")
    previewFrame.mainText:SetFont(TS.db.profile.display.font, TS.db.profile.display.fontSize or 14, "OUTLINE")
    previewFrame.mainText:SetText("Target Dummy: 65%")

    -----------------------------------------------------
    -- Threat list preview rows
    -----------------------------------------------------

    for i = 1, 5 do
        local row = CreateFrame("StatusBar", nil, previewFrame)
        row:SetMinMaxValues(0, 100)
        row:SetHeight(ROW_HEIGHT)

        if i == 1 then
            row:SetPoint("TOPLEFT", previewFrame.mainBar, "BOTTOMLEFT", 0, -10)
            row:SetPoint("TOPRIGHT", previewFrame.mainBar, "BOTTOMRIGHT", 0, -10)
        else
            row:SetPoint("TOPLEFT", previewRows[i-1], "BOTTOMLEFT", 0, -ROW_SPACING)
            row:SetPoint("TOPRIGHT", previewRows[i-1], "BOTTOMRIGHT", 0, -ROW_SPACING)
        end

        row.nameText = row:CreateFontString(nil, "OVERLAY")
        row.nameText:SetPoint("LEFT", 4, 0)

        row.pctText = row:CreateFontString(nil, "OVERLAY")
        row.pctText:SetPoint("RIGHT", -4, 0)

        previewRows[i] = row
    end

    -----------------------------------------------------
    -- Initial preview update
    -----------------------------------------------------
    ConfigDisplay:UpdatePreview()

	-----------------------------------------------------
	-- REGISTER PANEL
	-----------------------------------------------------
	local function RegisterDisplayCategory()
		local parent = Settings.GetCategory("ThreatSenseRoot")
		if not parent then
			return -- parent not ready yet
		end

		local category = Settings.RegisterCanvasLayoutCategory(panel, "Display")
		category.parent = parent
		Settings.RegisterAddOnCategory(category)

		print("ThreatSense: Display category registered")
	end

	-----------------------------------------------------
	-- Register when Settings UI is ready
	-----------------------------------------------------
	local f = CreateFrame("Frame")
		f:RegisterEvent("SETTINGS_LOADED")
		f:SetScript("OnEvent", RegisterDisplayCategory)
	end

---------------------------------------------------------
-- Update Preview Window
---------------------------------------------------------

function ConfigDisplay:UpdatePreview()
    if not previewFrame then return end

    local settings = TS.db.profile.display

    -----------------------------------------------------
    -- Main bar
    -----------------------------------------------------
    previewFrame.mainBar:SetHeight(settings.height)
    previewFrame.mainBar:SetScale(settings.scale)
    previewFrame.mainBar:SetStatusBarTexture(settings.barTexture)

    previewFrame.mainText:SetFont(settings.font, settings.fontSize or 14, "OUTLINE")
    previewFrame.mainText:SetText("Target Dummy: 65%")

    -----------------------------------------------------
    -- Fake data
    -----------------------------------------------------
    local fakeData = {
        { name = "You", pct = 65, class = "WARRIOR" },
        { name = "Magey", pct = 55, class = "MAGE" },
        { name = "Stabby", pct = 42, class = "ROGUE" },
        { name = "Healz", pct = 18, class = "PRIEST" },
        { name = "Tanky", pct = 5, class = "PALADIN" },
    }

    -----------------------------------------------------
    -- Rows
    -----------------------------------------------------
    for i, row in ipairs(previewRows) do
        if i <= settings.maxEntries then
            local data = fakeData[i]
            row:Show()

            row:SetValue(data.pct)
            row:SetStatusBarTexture(settings.barTexture)

            local r, g, b = TS.Utils:GetThreatColor(data.pct)
            row:SetStatusBarColor(r, g, b, 1)

            local classColor = RAID_CLASS_COLORS[data.class] or { r = 1, g = 1, b = 1 }

            row.nameText:SetFont(settings.font, settings.fontSize - 1, "OUTLINE")
            row.nameText:SetText(data.name)
            row.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

            if settings.showPercentage then
                row.pctText:SetFont(settings.font, settings.fontSize - 1, "OUTLINE")
                row.pctText:SetText(data.pct .. "%")
            else
                row.pctText:SetText("")
            end

            row:SetHeight(ROW_HEIGHT)
            row:SetScale(settings.scale)
        else
            row:Hide()
        end
    end
end

return ConfigDisplay