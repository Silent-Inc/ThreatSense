-- ThreatSense: WarningsAdvanced.lua
-- Advanced warning configuration (profile-aware, WarningEngine 2.0)

local ADDON_NAME, TS = ...
local WarningsAdvanced = {}
TS.WarningsAdvanced = WarningsAdvanced

local LSM = LibStub("LibSharedMedia-3.0", true)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function Header(layout, text)
    local h = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    h:SetText(text)
    h:SetPoint("TOPLEFT", 0, -12)
    return h
end

local function FireProfileChanged()
    TS.EventBus:Send("PROFILE_CHANGED")
    if TS.WarningPreview:IsActive() then
        TS.WarningPreview:StartRandom()
    end
end

local function Checkbox(layout, label, key, description)
    local db = TS.db.profile.warnings

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.Boolean,
        db[key]
    )

    Settings.CreateCheckbox(layout, setting, label, description)

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

local function Slider(layout, label, key, min, max, step, description)
    local db = TS.db.profile.warnings

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.Number,
        db[key]
    )

    Settings.CreateSlider(
        layout,
        setting,
        label,
        description,
        min,
        max,
        step
    )

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

local function ColorPicker(layout, label, key, default)
    local db = TS.db.profile.colors.warnings

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.Color,
        db[key] or default
    )

    Settings.CreateColorPicker(layout, setting, label, "Adjust this warning color.")

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

local function LSMDropdown(layout, label, key, mediaType, description)
    local db = TS.db.profile.warnings

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.String,
        db[key]
    )

    local function BuildOptions()
        local opts = {}
        if LSM then
            for _, name in ipairs(LSM:List(mediaType)) do
                table.insert(opts, { text = name, value = name })
            end
        end
        return opts
    end

    Settings.CreateDropdown(layout, setting, BuildOptions(), label, description)

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function WarningsAdvanced:Initialize()
    local categoryName = TS.Categories.WARNINGS_ADV
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    local db = TS.db.profile.warnings

    ------------------------------------------------------------
    -- WARNING TYPES
    ------------------------------------------------------------
    Header(layout, "Warning Types")

    Checkbox(layout, "Taunt Warning", "warnTaunt",
        "Show a warning when another player is tanking your target.")

    Checkbox(layout, "Losing Aggro Warning", "warnLosingAggro",
        "Show a warning when another player is close to overtaking your threat.")

    Checkbox(layout, "Aggro Lost Warning", "warnAggroLost",
        "Show a warning when you lose aggro on your target.")

    Checkbox(layout, "Pulling Aggro Warning", "warnPullingAggro",
        "Show a warning when you are close to pulling aggro.")

    Checkbox(layout, "Aggro Pulled Warning", "warnAggroPulled",
        "Show a warning when you pull aggro.")

    Checkbox(layout, "Drop Threat Warning", "warnDropThreat",
        "Show a warning when you should reduce threat.")

    ------------------------------------------------------------
    -- THRESHOLDS
    ------------------------------------------------------------
    Header(layout, "Thresholds")

    Slider(layout, "Tank: Losing Aggro %", "tankLosingAggroThreshold",
        50, 100, 1,
        "Show a warning when another player reaches this percentage of your threat.")

    Slider(layout, "DPS: Pulling Aggro %", "dpsPullingAggroThreshold",
        50, 100, 1,
        "Show a warning when you reach this percentage of the tank's threat.")

    Slider(layout, "DPS: Drop Threat %", "dpsDropThreatThreshold",
        50, 100, 1,
        "Show a warning when you should reduce threat.")

    Slider(layout, "Healer: Pulling Aggro %", "healerPullingAggroThreshold",
        50, 100, 1,
        "Show a warning when you reach this percentage of the tank's threat.")

    ------------------------------------------------------------
    -- VISUALS
    ------------------------------------------------------------
    Header(layout, "Visuals")

    Slider(layout, "Icon Size", "warningIconSize",
        16, 128, 1,
        "Adjust the size of the warning icon.")

    local styleSetting = Settings.RegisterAddOnSetting(
        category,
        "WarningStyle",
        nil,
        Settings.VarType.String,
        db.style
    )

    local styleOptions = {
        { text = "Icon Only", value = "ICON" },
        { text = "Text Only", value = "TEXT" },
        { text = "Icon + Text", value = "BOTH" },
    }

    Settings.CreateDropdown(
        layout,
        styleSetting,
        styleOptions,
        "Warning Style",
        "Choose how warnings are displayed."
    )

    styleSetting:SetValueChangedCallback(function(value)
        db.style = value
        FireProfileChanged()
    end)

    ------------------------------------------------------------
    -- AUDIO
    ------------------------------------------------------------
    Header(layout, "Audio")

    LSMDropdown(layout, "Warning Sound", "sound", "sound",
        "Select a sound to play when a warning triggers.")

    Slider(layout, "Sound Volume", "soundVolume",
        0, 1, 0.05,
        "Adjust the volume of warning sounds.")

    Settings.CreateControlButton(
        layout,
        "Test Sound",
        "Play the selected warning sound.",
        function()
            local sound = db.sound
            if sound and sound ~= "" and LSM then
                local path = LSM:Fetch("sound", sound)
                if path then
                    PlaySoundFile(path, "Master")
                end
            end
        end
    )

    ------------------------------------------------------------
    -- WARNING COLORS
    ------------------------------------------------------------
    Header(layout, "Warning Colors")

    ColorPicker(layout, "Aggro Lost", "AGGRO_LOST",
        { r = 1, g = 0.2, b = 0.2, a = 1 })

    ColorPicker(layout, "Taunt Needed", "TAUNT",
        { r = 1, g = 0.5, b = 0.1, a = 1 })

    ColorPicker(layout, "Losing Aggro", "LOSING_AGGRO",
        { r = 1, g = 0.8, b = 0.1, a = 1 })

    ColorPicker(layout, "Pulling Aggro", "PULLING_AGGRO",
        { r = 1, g = 0.8, b = 0.1, a = 1 })

    ColorPicker(layout, "Aggro Pulled", "AGGRO_PULLED",
        { r = 1, g = 0.2, b = 0.2, a = 1 })

    ------------------------------------------------------------
    -- PREVIEW
    ------------------------------------------------------------
    Header(layout, "Preview")

    Settings.CreateControlButton(
        layout,
        "Preview Random Warning",
        "Show a random warning scenario.",
        function()
            if TS.WarningPreview:IsActive() then
                TS.WarningPreview:Stop()
            else
                TS.WarningPreview:StartRandom()
            end
        end
    )

    Settings.CreateControlButton(
        layout,
        "Preview: Tank Losing Aggro",
        "Simulate a tank losing aggro.",
        function()
            TS.WarningPreview:StartScenario("TANK_LOSING")
        end
    )

    Settings.CreateControlButton(
        layout,
        "Preview: DPS Pulling",
        "Simulate a DPS pulling threat.",
        function()
            TS.WarningPreview:StartScenario("DPS_PULLING")
        end
    )

    Settings.CreateControlButton(
        layout,
        "Stop Preview",
        "Stop all warning previews.",
        function()
            TS.WarningPreview:Stop()
        end
    )

    ------------------------------------------------------------
    -- Register
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end

return WarningsAdvanced