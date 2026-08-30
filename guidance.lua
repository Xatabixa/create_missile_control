-- guidance.lua
-- Missile guidance system

-- Wait for global state
if state == nil then
    state = {}
end

-- Initialize guidance data
state.guidance = state.guidance or {}

local guidance = state.guidance

guidance.enabled = true
guidance.mode = guidance.mode or "VECTOR"
guidance.target = guidance.target or {
    x = 0,
    y = 0,
    z = 0
}

guidance.command = guidance.command or {
    x = 0,
    y = 0,
    z = 0
}

-- Get target coordinates
local function getTarget()
    if target ~= nil then
        if target.x ~= nil then
            guidance.target.x = target.x
        end

        if target.y ~= nil then
            guidance.target.y = target.y
        end

        if target.z ~= nil then
            guidance.target.z = target.z
        end
    end
end

-- Calculate simple guidance vector
local function calculateGuidance()
    getTarget()

    guidance.command.x = guidance.target.x
    guidance.command.y = guidance.target.y
    guidance.command.z = guidance.target.z
end

-- Main guidance update
function guidance.update()
    if not guidance.enabled then
        return
    end

    calculateGuidance()
end

-- Status
function guidance.getStatus()
    return {
        enabled = guidance.enabled,
        mode = guidance.mode,
        target = guidance.target,
        command = guidance.command
    }
end

-- Initial calculation
guidance.update()