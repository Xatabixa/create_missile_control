-- Shared missile control state

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

        positionValid = false,

        velocity = {
            x = 0,
            y = 0,
            z = 0
        },

        altitude = 0,
        verticalSpeed = 0,
        airPressure = 0,

        pitch = 0,
        roll = 0,
        heading = 0,

        angularRateX = 0,
        angularRateY = 0,
        angularRateZ = 0,

        accelerationX = 0,
        accelerationY = 0,
        accelerationZ = 0,

        gravityX = 0,
        gravityY = 0,
        gravityZ = 0,

        bearing = 0,
        relativeAngle = 0,
        elevation = 0,
        distance = 0,
        closureRate = 0,

        hasNavTarget = false,

        altitudeSensor = false,
        gimbalSensor = false,
        navigationTable = false,
        gps = false
    },

    guidance = {

        online = false,

        commandX = 0,
        commandY = 0,

        active = false
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

    display = {
        online = false
    }
}

return state