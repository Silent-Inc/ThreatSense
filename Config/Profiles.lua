-- ThreatSense: Profiles.lua
-- Modern profile management (AceDB, ProfileManager 2.0)

local ADDON_NAME, TS = ...
local Profiles = {}
TS.Profiles = Profiles

local PM = TS.ProfileManager

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

    -- Stop previews when switching profiles
    if TS.DisplayPreview and TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Stop()
    end
    if TS.WarningPreview and TS.WarningPreview:IsActive() then
        TS.WarningPreview:Stop()
    end
end

local function BuildProfileOptions()
    local opts = {}
    for name in pairs(TS.db.profiles) do
        table.insert(opts, { text = name, value = name })
    end
    return opts
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Profiles:Initialize()
    local categoryName = TS.Categories.PROFILES
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    ------------------------------------------------------------
    -- ACTIVE PROFILE DROPDOWN
    ------------------------------------------------------------
    Header(layout, "Active Profile")

    local activeProfile = PM:GetActiveProfileName()

    local profileSetting = Settings.RegisterAddOnSetting(
        category,
        "ActiveProfile",
        nil,
        Settings.VarType.String,
        activeProfile
    )

    Settings.CreateDropdown(
        layout,
        profileSetting,
        BuildProfileOptions(),
        "Active Profile",
        "Select which profile this character uses."
    )

    profileSetting:SetValueChangedCallback(function(newProfile)
        TS.db:SetProfile(newProfile)
        FireProfileChanged()
    end)

    ------------------------------------------------------------
    -- PROFILE MANAGEMENT
    ------------------------------------------------------------
    Header(layout, "Profile Management")

    -- Create new profile
    Settings.CreateControlButton(
        layout,
        "Create New Profile",
        "Create a new empty profile.",
        function()
            local name = "Profile " .. math.random(1000, 9999)
            TS.db:SetProfile(name) -- AceDB auto-creates it
            FireProfileChanged()
        end
    )

    -- Copy profile
    Settings.CreateControlButton(
        layout,
        "Copy Current Profile",
        "Duplicate the active profile.",
        function()
            local current = PM:GetActiveProfileName()
            local name = current .. " Copy"

            TS.db:CopyProfile(current)
            TS.db:SetProfile(name)

            FireProfileChanged()
        end
    )

    -- Reset profile
    Settings.CreateControlButton(
        layout,
        "Reset Profile",
        "Reset the active profile to default settings.",
        function()
            TS.db:ResetProfile()
            FireProfileChanged()
        end
    )

    -- Delete profile
    Settings.CreateControlButton(
        layout,
        "Delete Profile",
        "Delete the active profile (except Default).",
        function()
            local current = PM:GetActiveProfileName()
            if current ~= "Default" then
                TS.db:DeleteProfile(current)
                TS.db:SetProfile("Default")
                FireProfileChanged()
            end
        end
    )

    ------------------------------------------------------------
    -- ROLE-AWARE PROFILE SWITCHING
    ------------------------------------------------------------
    Header(layout, "Role-Based Profile Switching")

    local roleDB = TS.db.profile.roles

    -- Enable auto-switch
    local autoSwitchSetting = Settings.RegisterAddOnSetting(
        category,
        "AutoSwitchProfiles",
        nil,
        Settings.VarType.Boolean,
        roleDB.autoSwitch
    )

    Settings.CreateCheckbox(
        layout,
        autoSwitchSetting,
        "Enable Auto-Switch",
        "Automatically switch profiles when your role changes."
    )

    autoSwitchSetting:SetValueChangedCallback(function(value)
        roleDB.autoSwitch = value
        FireProfileChanged()
    end)

    -- Role-specific profile dropdowns
    local roles = { "TANK", "HEALER", "DPS" }

    for _, role in ipairs(roles) do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "ProfileFor" .. role,
            nil,
            Settings.VarType.String,
            roleDB[role]
        )

        Settings.CreateDropdown(
            layout,
            setting,
            BuildProfileOptions(),
            role .. " Profile",
            "Profile to use when your role is " .. role .. "."
        )

        setting:SetValueChangedCallback(function(value)
            roleDB[role] = value
            FireProfileChanged()
        end)
    end

    ------------------------------------------------------------
    -- REGISTER
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end

return Profiles