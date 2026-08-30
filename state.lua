-- Shared missile control state

local state = {
    system = {
        running = true,
        mode = "DRY TEST",
        status = "STARTING",
        controlEnabled = false,
        error = nil
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

        position = { x = 0, y = 0, z = 0 },
        positionValid = false,
        gps = false,

        velocity = { x = 0, y = 0, z = 0 },
        speed = 0,

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
        gravityMagnitude = 0,

        bearing = 0,
        relativeAngle = 0,
        elevation = 0,
        distance = 0,
        closureRate = 0,

        hasNavTarget = false,

        navigationTable = false,
        altitudeSensor = false,
        gimbalSensor = false,

        velocitySensorX = false,
        velocitySensorY = false,
        velocitySensorZ = false,

        lastUpdate = 0,
        error = nil
    },

    guidance = {
        online = false,
        status = "OFFLINE",
        active = false,

        commandX = 0,
        commandY = 0,

        yawError = 0,
        pitchError = 0,

        targetBearing = 0,
        targetElevation = 0
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

        error = nil
    },

    display = {
        online = false,
        page = 1
    }
}

return state