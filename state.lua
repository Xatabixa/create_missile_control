-- Shared missile control state

local state = {

    system = {
        running = true,
        mode = "DRY TEST",
        status = "INITIALIZING"
    },

    -- The missile has an impact point, not a target.
    impactPoint = {
        x = 0,
        y = 0,
        z = 0,
        set = false
    },

    navigation = {

        online = false,
        status = "OFFLINE",

        bearing = 0,
        heading = 0,
        relativeAngle = 0,

        verticalOffset = 0,
        distance = 0,
        closureRate = 0,

        orientation = nil,

        lastUpdate = 0,
        updateCount = 0
    },

    guidance = {

        online = false,
        status = "OFFLINE",

        commandX = 0,
        commandY = 0,

        lastUpdate = 0,
        updateCount = 0
    },

    thruster = {

        online = false,
        status = "OFFLINE",

        power = 0,
        thrust = 0,

        vectorX = 0,
        vectorY = 0,

        targetVectorX = 0,
        targetVectorY = 0,

        lastUpdate = 0,
        updateCount = 0
    }
}

return state