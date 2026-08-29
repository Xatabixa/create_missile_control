-- Shared missile system state

local state = {

    system = {
        running = true,
        mode = "DRY TEST"
    },

    target = {
        x = 0,
        y = 0,
        z = 0,
        set = false
    },

    navigation = {

        online = false,

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

        gravity = 0,

        heading = 0,
        bearing = 0,
        relativeAngle = 0,

        elevation = 0,
        distance = 0,
        closureRate = 0
    },

    guidance = {

        online = false,

        commandX = 0,
        commandY = 0
    },

    thruster = {

        online = false,

        power = 0,
        thrust = 0,

        vectorX = 0,
        vectorY = 0,

        targetVectorX = 0,
        targetVectorY = 0
    }
}

return state