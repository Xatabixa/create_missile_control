-- Shared missile state
-- All modules communicate through this table.

local state = {

    system = {
        mode = "DRY TEST",
        running = true
    },

    navigation = {

        online = false,

        hasTarget = false,

        closureRate = 0,

        relativeAngle = 0,

        bearing = 0,

        elevation = 0,

        distance = 0,

        heading = 0,

        position = {
            x = 0,
            y = 0,
            z = 0
        },

        velocity = {
            x = 0,
            y = 0,
            z = 0
        },

        acceleration = {
            x = 0,
            y = 0,
            z = 0
        },

        gravity = 0
    },

    target = {

        x = 0,
        y = 0,
        z = 0,

        set = false
    },

    guidance = {

        online = false,

        commandX = 0,
        commandY = 0,

        errorX = 0,
        errorY = 0
    },

    thruster = {

        online = false,

        power = 0,
        thrust = 0,

        vectorX = 0,
        vectorY = 0,

        targetVectorX = 0,
        targetVectorY = 0

    },

    sensors = {

        gimbalOnline = false,

        pitch = 0,

        roll = 0,

        yaw = 0,

        pitchRate = 0,

        rollRate = 0,

        yawRate = 0
    }
}

return state