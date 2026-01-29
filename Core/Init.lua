-- ThreatSense: Init.lua
-- Central initialization and module loading

local ADDON_NAME, TS = ...

TS.Core = {}
local Core = TS.Core

function Core:Initialize()
    -- Initialize core systems
    TS.Utils:Initialize()
    TS.EventBus:Initialize()

    -- Initialize engines
    TS.ThreatEngine:Initialize()
    TS.WarningEngine:Initialize()

    -- Initialize UI
    -- (UI modules will register themselves)

    -- Initialize config panels
    -- (Config modules will register themselves)

    print("ThreatSense loaded")
end