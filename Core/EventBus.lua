-- ThreatSense: EventBus.lua
-- Lightweight pub/sub event system

local ADDON_NAME, TS = ...

TS.EventBus = {}
local Bus = TS.EventBus

Bus.listeners = {}

function Bus:Register(event, callback)
    if not Bus.listeners[event] then
        Bus.listeners[event] = {}
    end
    table.insert(Bus.listeners[event], callback)
end

function Bus:Send(event, ...)
    local list = Bus.listeners[event]
    if not list then return end
    for _, callback in ipairs(list) do
        callback(...)
    end
end

function Bus:Initialize()
    -- Reserved for future expansion
end