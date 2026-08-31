-- Shared missile control state
-- CC:Tweaked
--
-- Single shared state table for all modules.
-- No require().

local state = {

    --------------------------------------------------
    -- SYSTEM
    --------------------------------------------------

    system = {

        running = true,

        mode = "DRY TEST",

        status = "STARTING",

        controlEnabled = false,

        error = nil
    },


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    target = {

        x = 0,

        y = 0,

        z = 0,

        set = false,

        revision = 0
    },


    --------------------------------------------------
    -- START POSITION
    --------------------------------------------------

    startPosition = {

        x = 0,

        y = 0,

        z = 0,

        set = false
    },


    --------------------------------------------------
    -- NAVIGATION
    --------------------------------------------------

    navigation = {

        online = false,

        status = "OFFLINE",

        error = nil,

        lastUpdate = 0,


        --------------------------------------------------
        -- DEVICE STATUS
        --------------------------------------------------

        navigationTable = false,

        navigationTableStatus = "OFF",

        navigationTarget = false,

        navigationTargetStatus = "NO TARGET",

        altitudeSensor = false,

        gimbalSensor = false,

        velocitySensor = false,

        velocitySensorX = false,

        velocitySensorY = false,

        velocitySensorZ = false,


        --------------------------------------------------
        -- POSITION
        --------------------------------------------------

        position = {

            x = 0,

            y = 0,

            z = 0
        },

        positionValid = false,

        startAltitude = 0,


        --------------------------------------------------
        -- WORLD VELOCITY
        --------------------------------------------------

        velocity = {

            x = 0,

            y = 0,

            z = 0
        },

        speed = 0,


        --------------------------------------------------
        -- BODY VELOCITY
        --------------------------------------------------

        bodyVelocity = {

            x = 0,

            y = 0,

            z = 0
        },


        --------------------------------------------------
        -- ALTITUDE
        --------------------------------------------------

        altitude = 0,

        verticalSpeed = 0,

        airPressure = 0,


        --------------------------------------------------
        -- ORIENTATION
        --------------------------------------------------

        heading = 0,

        pitch = 0,

        roll = 0,


        --------------------------------------------------
        -- QUATERNION
        --------------------------------------------------

        orientation = {

            x = 0,

            y = 0,

            z = 0,

            w = 1
        },


        --------------------------------------------------
        -- FORWARD VECTOR
        --------------------------------------------------

        forward = {

            x = 0,

            y = 0,

            z = 1
        },


        --------------------------------------------------
        -- ANGULAR VELOCITY
        --------------------------------------------------

        angularRateX = 0,

        angularRateY = 0,

        angularRateZ = 0,


        --------------------------------------------------
        -- ACCELERATION
        --------------------------------------------------

        accelerationX = 0,

        accelerationY = 0,

        accelerationZ = 0,


        --------------------------------------------------
        -- GRAVITY
        --------------------------------------------------

        gravityX = 0,

        gravityY = 0,

        gravityZ = 0,

        gravityMagnitude = 0,


        --------------------------------------------------
        -- MANUAL TARGET VECTOR
        --------------------------------------------------

        targetDeltaX = 0,

        targetDeltaY = 0,

        targetDeltaZ = 0,

        targetDistance = 0,

        hasNavTarget = false,


        --------------------------------------------------
        -- TARGET VECTOR IN BODY FRAME
        --------------------------------------------------

        localTargetX = 0,

        localTargetY = 0,

        localTargetZ = 0,


        --------------------------------------------------
        -- DIRECT GUIDANCE ANGLES
        --------------------------------------------------

        targetYaw = 0,

        targetPitch = 0

    },


    --------------------------------------------------
    -- GUIDANCE
    --------------------------------------------------

    guidance = {

        online = false,

        status = "OFFLINE",

        active = false,


        commandX = 0,

        commandY = 0,


        yawError = 0,

        pitchError = 0,


        yawRate = 0,

        pitchRate = 0,


        yawP = 0,

        yawI = 0,

        yawD = 0,


        pitchP = 0,

        pitchI = 0,

        pitchD = 0,


        yawIntegral = 0,

        pitchIntegral = 0,


        targetBearing = 0,

        targetElevation = 0,


        targetDX = 0,

        targetDY = 0,

        targetDZ = 0,


        distance = 0,


        flightPhase = "READY",

        flightTime = 0,

        phaseTime = 0,


        boostMode = false,

        pitchOverMode = false,

        cruiseMode = false,

        terminalMode = false,


        flightMaxVector = 0,


        boostAltitude = 100,

        cruiseAltitude = 300,

        terminalDistance = 500

    },


    --------------------------------------------------
    -- THRUSTER
    --------------------------------------------------

    thruster = {

        online = false,

        status = "OFFLINE",

        error = nil,


        power = 0,

        thrust = 0,


        vectorX = 0,

        vectorY = 0,


        targetVectorX = 0,

        targetVectorY = 0,


        engineCount = 0,

        commandedEngines = 0,


        engines = {},

        commandErrors = {}

    },


    --------------------------------------------------
    -- FLIGHT
    --------------------------------------------------

    flight = {

        online = false,

        active = false,

        phase = "READY",

        status = "READY",


        elapsed = 0,

        phaseElapsed = 0,


        launchTime = nil,

        phaseStartTime = 0,


        phaseChanged = false,


        boost = false,

        pitchOver = false,

        cruise = false,

        terminal = false,


        impact = false,

        targetReached = false,

        abort = false,


        altitude = 0,

        targetDistance = 0

    },


    --------------------------------------------------
    -- DISPLAY
    --------------------------------------------------

    display = {

        online = false,

        page = 1

    }

}


return state