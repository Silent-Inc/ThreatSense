-- ThreatSense: Init.lua
-- Central initialization and module loading

local ADDON_NAME, TS = ...

------------------------------------------------------------
-- Namespace Setup
------------------------------------------------------------
TS.Core = TS.Core or {}
local Core = TS.Core

-- Saved variables reference (populated on ADDON_LOADED)
TS.db = TS.db or nil

------------------------------------------------------------
-- Event Frame
------------------------------------------------------------
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON_NAME then
            Core:OnAddonLoaded()
        end

    elseif event == "PLAYER_LOGIN" then
        Core:OnPlayerLogin()
    end
end)

------------------------------------------------------------
-- ADDON_LOADED
-- Load saved variables, run migrations, prepare systems
------------------------------------------------------------
function Core:OnAddonLoaded()
    -- Initialize saved variables
    ThreatSenseDB = ThreatSenseDB or {}
    TS.db = ThreatSenseDB

    -- Optional DB migrations (only runs if Migration.lua is loaded)
    if TS.Migration and TS.Migration.Run then
        TS.Migration:Run()
    end

    -- Initialize utility helpers
    if TS.Utils and TS.Utils.Initialize then
        TS.Utils:Initialize()
    end

    -- Initialize EventBus early (required by most systems)
    if TS.EventBus and TS.EventBus.Initialize then
        TS.EventBus:Initialize()
    end

    -- Initialize SharedMedia wrapper
    -- (Fix: this was missing; engines depend on it)
    if TS.Media and TS.Media.Initialize then
        TS.Media:Initialize()
    end

    -- Initialize profile system
    -- (Fix: this was missing; engines depend on profile defaults)
    if TS.ProfileManager and TS.ProfileManager.Initialize then
        TS.ProfileManager:Initialize()
    end

    -- Initialize role detection
    -- (Fix: this was missing; threat logic depends on role)
    if TS.RoleManager and TS.RoleManager.Initialize then
        TS.RoleManager:Initialize()
    end
    
	-- Initialize GroupManager
    -- (Fix: this was missing)
    if TS.GroupManager and TS.GroupManager.Initialize then
        TS.GroupManager:Initialize()
    end

    -- Initialize smoothing engine
    -- (Fix: missing; ThreatBar uses smoothing)
    if TS.Smoothing and TS.Smoothing.Initialize then
        TS.Smoothing:Initialize()
    end

    -- Initialize core logic engines (now safe because dependencies above are ready)
    if TS.ThreatEngine and TS.ThreatEngine.Initialize then
        TS.ThreatEngine:Initialize()
    end

    if TS.WarningEngine and TS.WarningEngine.Initialize then
        TS.WarningEngine:Initialize()
    end
end

------------------------------------------------------------
-- PLAYER_LOGIN
-- Initialize UI, Config panels, and final systems
------------------------------------------------------------
function Core:OnPlayerLogin()
    --------------------------------------------------------
    -- UI: Display
    --------------------------------------------------------
    if TS.ThreatBar and TS.ThreatBar.Initialize then
        TS.ThreatBar:Initialize()
    end

    if TS.ThreatList and TS.ThreatList.Initialize then
        TS.ThreatList:Initialize()
    end

    --------------------------------------------------------
    -- UI: Warnings
    --------------------------------------------------------
    if TS.WarningFrame and TS.WarningFrame.Initialize then
        TS.WarningFrame:Initialize()
    end

    --------------------------------------------------------
    -- UI: Display Mode
    --------------------------------------------------------
    if TS.DisplayMode and TS.DisplayMode.Set then
        -- Ensure a safe default if mode is nil
        TS.DisplayMode:Set(TS.DisplayMode.mode or "BAR_ONLY")
    end

    --------------------------------------------------------
    -- UI: Preview Systems
    --------------------------------------------------------
    if TS.DisplayPreview and TS.DisplayPreview.Initialize then
        TS.DisplayPreview:Initialize()
    end

    if TS.WarningPreview and TS.WarningPreview.Initialize then
        TS.WarningPreview:Initialize()
    end

    --------------------------------------------------------
    -- Config Panels
    --------------------------------------------------------
    if TS.ConfigParent and TS.ConfigParent.Initialize then
        TS.ConfigParent:Initialize()
    end

    if TS.ConfigDisplay and TS.ConfigDisplay.Initialize then
        TS.ConfigDisplay:Initialize()
    end

    if TS.ConfigDisplayAdvanced and TS.ConfigDisplayAdvanced.Initialize then
        TS.ConfigDisplayAdvanced:Initialize()
    end

    if TS.ConfigWarnings and TS.ConfigWarnings.Initialize then
        TS.ConfigWarnings:Initialize()
    end

    if TS.ConfigWarningsAdvanced and TS.ConfigWarningsAdvanced.Initialize then
        TS.ConfigWarningsAdvanced:Initialize()
    end

    if TS.ConfigProfiles and TS.ConfigProfiles.Initialize then
        TS.ConfigProfiles:Initialize()
    end

    if TS.ConfigRoles and TS.ConfigRoles.Initialize then
        TS.ConfigRoles:Initialize()
    end

    if TS.ConfigReset and TS.ConfigReset.Initialize then
        TS.ConfigReset:Initialize()
    end

    --------------------------------------------------------
    -- Optional developer tools (only if loaded)
    --------------------------------------------------------
    if TS.DevMode and TS.DevMode.Initialize then
        TS.DevMode:Initialize()
    end

    print("|cff00ff00ThreatSense loaded successfully.|r")
end