-- Shared missile control state.
-- This file is loaded once by launcher.lua.
-- Do not use require() in ComputerCraft.

local state = {
    system = {
        running = true,
        status = "STARTING",
        mode = "STANDBY",
        controlEnabled = false,
        error = nil,
        tick = 0
    },

    target = {
        x = 0,
        y = 0,
        z = 0,
        set = false,
        revision = 0
    },

    navigation = {
        online = false,
        status = "OFFLINE",

        gps = false,
        navTable = false,
        gimbal = false,

        x = 0,
        y = 0,
        z = 0,

        vx = 0,
        vy = 0,
        vz = 0,

        speed = 0,
        altitude = 0,
        verticalSpeed = 0,

        heading = 0,
        pitch = 0,
        roll = 0,

        distance = 0,
        groundDistance = 0,
        verticalOffset = 0,
        bearing = 0,

        bodyX = 0,
        bodyY = 0,
        bodyZ = 0,

        lastUpdate = 0,
        updateCount = 0
    },

    guidance = {
        online = false,
        status = "OFFLINE",

        yawError = 0,
        pitchError = 0,

        commandX = 0,
        commandY = 0,

        lastUpdate = 0,
        updateCount = 0
    },

    actuator = {
        online = false,
        status = "OFFLINE",

        type = "NONE",

        vectorX = 0,
        vectorY = 0,

        commandX = 0,
        commandY = 0,

        thrust = 0,
        power = 0,

        lastUpdate = 0,
        updateCount = 0
    }
}

return state