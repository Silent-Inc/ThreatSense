local ADDON_NAME, TS = ...

TS.DisplayMode = {
    mode = "BAR_ONLY", -- default
}

local Mode = TS.DisplayMode

Mode.MODES = {
    BAR_ONLY = "BAR_ONLY",
    BAR_AND_LIST = "BAR_AND_LIST",
    LIST_ONLY = "LIST_ONLY",
}

------------------------------------------------------------
-- Set display mode
------------------------------------------------------------
function Mode:Set(mode)
    if not self.MODES[mode] then
        TS.Utils:Debug("Invalid display mode: " .. tostring(mode))
        return
    end

    self.mode = mode
    TS.Utils:Debug("Display mode set to: " .. mode)

    TS.EventBus:Emit("DISPLAY_MODE_CHANGED", mode)
end

------------------------------------------------------------
-- Get current mode
------------------------------------------------------------
function Mode:Get()
    return self.mode
end