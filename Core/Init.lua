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

    -- Run DB migrations if needed
    if TS.Migration and TS.Migration.Run then
        TS.Migration:Run()
    end

    -- Initialize Core systems
    if TS.Utils and TS.Utils.Initialize then
        TS.Utils:Initialize()
    end

    if TS.EventBus and TS.EventBus.Initialize then
        TS.EventBus:Initialize()
    end

    -- Initialize Engines (logic only, no UI yet)
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
    -- Initialize UI modules
    if TS.ThreatBar and TS.ThreatBar.Initialize then
        TS.ThreatBar:Initialize()
    end

    if TS.ThreatList and TS.ThreatList.Initialize then
        TS.ThreatList:Initialize()
    end

    if TS.WarningFrame and TS.WarningFrame.Initialize then
        TS.WarningFrame:Initialize()
    end

    if TS.DisplayMode and TS.DisplayMode.Set then
        TS.DisplayMode:Set(TS.DisplayMode.mode)
    end

    -- Initialize preview systems
    if TS.DisplayPreview and TS.DisplayPreview.Initialize then
        TS.DisplayPreview:Initialize()
    end

    if TS.WarningPreview and TS.WarningPreview.Initialize then
        TS.WarningPreview:Initialize()
    end

    -- Initialize Config panels
    if TS.Config and TS.Config.Initialize then
        TS.Config:Initialize()
    end

    if TS.ConfigDisplay and TS.ConfigDisplay.Initialize then
        TS.ConfigDisplay:Initialize()
    end

    if TS.ConfigWarnings and TS.ConfigWarnings.Initialize then
        TS.ConfigWarnings:Initialize()
    end

    if TS.ConfigProfiles and TS.ConfigProfiles.Initialize then
        TS.ConfigProfiles:Initialize()
    end

    if TS.ConfigRoles and TS.ConfigRoles.Initialize then
        TS.ConfigRoles:Initialize()
    end

    if TS.TestMode and TS.TestMode.Initialize then
        TS.TestMode:Initialize()
    end

    -- Optional developer tools
    if TS.DevMode and TS.DevMode.Initialize then
        TS.DevMode:Initialize()
    end

    print("|cff00ff00ThreatSense loaded successfully.|r")
end