-- ThreatSense: Warnings.lua
-- Modern warning configuration panel (profile-aware, WarningEngine 2.0)

local ADDON_NAME, TS = ...
local Warnings = {}
TS.Warnings = Warnings

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
function Warnings:Initialize()
    local categoryName = TS.Categories.WARNINGS
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    local db = TS.db.profile.warnings

    ------------------------------------------------------------
    -- ENABLE / DISABLE
    ------------------------------------------------------------
    Header(layout, "Warning System")

    Checkbox(layout,
        "Enable Warnings",
        "enabled",
        "Turn the warning system on or off."
    )

    ------------------------------------------------------------
    -- WARNING STYLE
    ------------------------------------------------------------
    Header(layout, "Warning Style")

    local styleSetting = Settings.RegisterAddOnSetting(
        category,
        "WarningStyle",
        nil,
        Settings.VarType.String,
        db.style
    )

    local styleOptions = {
        { text = "Icon Only",  value = "ICON" },
        { text = "Text Only",  value = "TEXT" },
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
    -- THRESHOLDS
    ------------------------------------------------------------
    Header(layout, "Warning Thresholds")

    Slider(layout,
        "Aggro Warning Threshold",
        "aggroThreshold",
        50, 100, 1,
        "Trigger warnings when threat exceeds this percentage."
    )

    Slider(layout,
        "Losing Aggro Threshold",
        "losingAggroThreshold",
        50, 100, 1,
        "Trigger warnings when another player approaches your threat."
    )

    ------------------------------------------------------------
    -- ANIMATION SETTINGS
    ------------------------------------------------------------
    Header(layout, "Warning Animations")

    local animSetting = Settings.RegisterAddOnSetting(
        category,
        "WarningAnimation",
        nil,
        Settings.VarType.String,
        db.animation
    )

    local animOptions = {
        { text = "Flash", value = "FLASH" },
        { text = "Pulse", value = "PULSE" },
        { text = "Shake", value = "SHAKE" },
        { text = "Fade",  value = "FADE" },
    }

    Settings.CreateDropdown(
        layout,
        animSetting,
        animOptions,
        "Animation Style",
        "Choose the animation used for warnings."
    )

    animSetting:SetValueChangedCallback(function(value)
        db.animation = value
        FireProfileChanged()
    end)

    ------------------------------------------------------------
    -- SOUND SETTINGS
    ------------------------------------------------------------
    Header(layout, "Warning Sounds")

    LSMDropdown(layout,
        "Warning Sound",
        "sound",
        "sound",
        "Sound played when a warning triggers."
    )

    Slider(layout,
        "Sound Cooldown (seconds)",
        "soundCooldown",
        0, 10, 0.5,
        "Minimum time between repeated warning sounds."
    )

    ------------------------------------------------------------
    -- WARNING COLORS
    ------------------------------------------------------------
    Header(layout, "Warning Colors")

    ColorPicker(layout, "Aggro Lost", "AGGRO_LOST", { r = 1, g = 0.2, b = 0.2, a = 1 })
    ColorPicker(layout, "Taunt Needed", "TAUNT", { r = 1, g = 0.5, b = 0.1, a = 1 })
    ColorPicker(layout, "Losing Aggro", "LOSING_AGGRO", { r = 1, g = 0.8, b = 0.1, a = 1 })
    ColorPicker(layout, "Pulling Aggro", "PULLING_AGGRO", { r = 1, g = 0.8, b = 0.1, a = 1 })
    ColorPicker(layout, "Aggro Pulled", "AGGRO_PULLED", { r = 1, g = 0.2, b = 0.2, a = 1 })

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

return Warnings