-- Missile Navigation System
-- CC:Tweaked
--
-- Navigation is based on:
--   Navigation Table
--   Gimbal Sensor
--   Altitude Sensor
--   Velocity Sensor
--
-- Manual target:
--   target.cfg
--
-- Manual start position:
--   start.cfg
--
-- IMPORTANT:
-- navigation.lua loads start.cfg itself.
-- This prevents startup race conditions between
-- target/display/navigation modules.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

local START_FILE = "start.cfg"


--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function isNumber(value)

    return type(value) == "number"
        and value == value

end


--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function safeCall(
    device,
    method,
    ...
)

    if not device then
        return false, nil
    end


    local fn =
        device[method]


    if type(fn) ~= "function" then
        return false, nil
    end


    local ok,
    a,
    b,
    c,
    d =
        pcall(
            fn,
            ...
        )


    if not ok then
        return false, nil
    end


    return true,
        a,
        b,
        c,
        d

end


--------------------------------------------------
-- FIND FIRST PERIPHERAL
--------------------------------------------------

local function findFirstType(
    peripheralType
)

    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            peripheralType
        ) then

            if peripheral.isPresent(
                name
            ) then

                local device =
                    peripheral.wrap(
                        name
                    )


                if device then

                    return device,
                        name

                end

            end

        end

    end


    return nil, nil

end


--------------------------------------------------
-- FIND VELOCITY SENSOR
--
-- One physical sensor may appear through
-- multiple modems. Only the first valid one
-- is used.
--------------------------------------------------

local function findVelocitySensor()

    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            "velocity_sensor"
        ) then

            if peripheral.isPresent(
                name
            ) then

                local device =
                    peripheral.wrap(
                        name
                    )


                if device then

                    return device,
                        name

                end

            end

        end

    end


    return nil, nil

end


--------------------------------------------------
-- VECTOR LENGTH
--------------------------------------------------

local function vectorLength(
    x,
    y,
    z
)

    return math.sqrt(
        x * x +
        y * y +
        z * z
    )

end


--------------------------------------------------
-- NORMALIZE VECTOR
--------------------------------------------------

local function normalize(
    x,
    y,
    z
)

    local length =
        vectorLength(
            x,
            y,
            z
        )


    if length <
        0.000001 then

        return 0, 0, 0

    end


    return
        x / length,
        y / length,
        z / length

end


--------------------------------------------------
-- NORMALIZE QUATERNION
--------------------------------------------------

local function normalizeQuaternion(
    x,
    y,
    z,
    w
)

    local length =
        math.sqrt(
            x * x +
            y * y +
            z * z +
            w * w
        )


    if length <
        0.000001 then

        return 0, 0, 0, 1

    end


    return
        x / length,
        y / length,
        z / length,
        w / length

end


--------------------------------------------------
-- ROTATE VECTOR BY QUATERNION
--------------------------------------------------

local function rotateVector(
    x,
    y,
    z,
    qx,
    qy,
    qz,
    qw
)

    local tx =
        2 *
        (
            qy * z -
            qz * y
        )


    local ty =
        2 *
        (
            qz * x -
            qx * z
        )


    local tz =
        2 *
        (
            qx * y -
            qy * x
        )


    local rx =
        x +
        qw * tx +
        (
            qy * tz -
            qz * ty
        )


    local ry =
        y +
        qw * ty +
        (
            qz * tx -
            qx * tz
        )


    local rz =
        z +
        qw * tz +
        (
            qx * ty -
            qy * tx
        )


    return rx, ry, rz

end


--------------------------------------------------
-- WORLD → BODY
--------------------------------------------------

local function worldToBody(
    x,
    y,
    z,
    qx,
    qy,
    qz,
    qw
)

    return rotateVector(
        x,
        y,
        z,
        -qx,
        -qy,
        -qz,
        qw
    )

end


--------------------------------------------------
-- BODY → WORLD
--------------------------------------------------

local function bodyToWorld(
    x,
    y,
    z,
    qx,
    qy,
    qz,
    qw
)

    return rotateVector(
        x,
        y,
        z,
        qx,
        qy,
        qz,
        qw
    )

end


--------------------------------------------------
-- LOAD START POSITION
--------------------------------------------------

local function loadStartPosition(
    state
)

    --------------------------------------------------
    -- First try state.
    --------------------------------------------------

    if type(
        state.startPosition
    ) == "table"
        and
        state.startPosition.set ==
        true then

        return
    end


    --------------------------------------------------
    -- Then read start.cfg directly.
    --------------------------------------------------

    if not fs.exists(
        START_FILE
    ) then

        return
    end


    local file =
        fs.open(
            START_FILE,
            "r"
        )


    if not file then

        return
    end


    local content =
        file.readAll()


    file.close()


    local data =
        textutils.unserialize(
            content
        )


    if type(data) ~=
        "table" then

        return
    end


    state.startPosition =
        state.startPosition
        or
        {}


    state.startPosition.x =
        tonumber(
            data.x
        )
        or
        0


    state.startPosition.y =
        tonumber(
            data.y
        )
        or
        0


    state.startPosition.z =
        tonumber(
            data.z
        )
        or
        0


    state.startPosition.set =
        data.set == true

end


--------------------------------------------------
-- INITIALIZE POSITION
--------------------------------------------------

local function initializePosition(
    state
)

    loadStartPosition(
        state
    )


    --------------------------------------------------
    -- Start from saved coordinates.
    --------------------------------------------------

    if type(
        state.startPosition
    ) == "table"
        and
        state.startPosition.set ==
        true then

        state.navigation.position.x =
            tonumber(
                state.startPosition.x
            )
            or
            0


        state.navigation.position.y =
            tonumber(
                state.startPosition.y
            )
            or
            0


        state.navigation.position.z =
            tonumber(
                state.startPosition.z
            )
            or
            0

    else

        state.navigation.position.x =
            0


        state.navigation.position.y =
            0


        state.navigation.position.z =
            0

    end

end


--------------------------------------------------
-- INITIAL STATE
--------------------------------------------------

local function initializeState(
    state
)

    state.navigation =
        state.navigation
        or {}


    state.navigation.online =
        false


    state.navigation.status =
        "OFFLINE"


    state.navigation.error =
        nil


    --------------------------------------------------
    -- DEVICE FLAGS
    --------------------------------------------------

    state.navigation.navigationTable =
        false


    state.navigation.navigationTableStatus =
        "OFF"


    state.navigation.navigationTarget =
        false


    state.navigation.navigationTargetStatus =
        "NO TARGET"


    state.navigation.altitudeSensor =
        false


    state.navigation.gimbalSensor =
        false


    state.navigation.velocitySensor =
        false


    state.navigation.velocitySensorX =
        false


    state.navigation.velocitySensorY =
        false


    state.navigation.velocitySensorZ =
        false


    --------------------------------------------------
    -- POSITION
    --------------------------------------------------

    state.navigation.position =
        {
            x = 0,
            y = 0,
            z = 0
        }


    state.navigation.positionValid =
        false


    --------------------------------------------------
    -- VELOCITY
    --------------------------------------------------

    state.navigation.velocity =
        {
            x = 0,
            y = 0,
            z = 0
        }


    state.navigation.bodyVelocity =
        {
            x = 0,
            y = 0,
            z = 0
        }


    state.navigation.speed =
        0


    --------------------------------------------------
    -- ALTITUDE
    --------------------------------------------------

    state.navigation.altitude =
        0


    state.navigation.verticalSpeed =
        0


    state.navigation.airPressure =
        0


    --------------------------------------------------
    -- ATTITUDE
    --------------------------------------------------

    state.navigation.heading =
        0


    state.navigation.pitch =
        0


    state.navigation.roll =
        0


    state.navigation.orientation =
        {
            x = 0,
            y = 0,
            z = 0,
            w = 1
        }


    state.navigation.forward =
        {
            x = 0,
            y = 0,
            z = 1
        }


    --------------------------------------------------
    -- RATES
    --------------------------------------------------

    state.navigation.angularRateX =
        0


    state.navigation.angularRateY =
        0


    state.navigation.angularRateZ =
        0


    --------------------------------------------------
    -- ACCELERATION
    --------------------------------------------------

    state.navigation.accelerationX =
        0


    state.navigation.accelerationY =
        0


    state.navigation.accelerationZ =
        0


    --------------------------------------------------
    -- GRAVITY
    --------------------------------------------------

    state.navigation.gravityX =
        0


    state.navigation.gravityY =
        0


    state.navigation.gravityZ =
        0


    state.navigation.gravityMagnitude =
        0


    --------------------------------------------------
    -- NAVIGATION TABLE DATA
    --------------------------------------------------

    state.navigation.bearing =
        0


    state.navigation.relativeAngle =
        0


    state.navigation.elevation =
        0


    state.navigation.navTableDistance =
        0


    state.navigation.closureRate =
        0


    --------------------------------------------------
    -- MANUAL TARGET
    --------------------------------------------------

    state.navigation.hasNavTarget =
        false


    state.navigation.targetDeltaX =
        0


    state.navigation.targetDeltaY =
        0


    state.navigation.targetDeltaZ =
        0


    state.navigation.targetDistance =
        0


    --------------------------------------------------
    -- BODY TARGET
    --------------------------------------------------

    state.navigation.localTargetX =
        0


    state.navigation.localTargetY =
        0


    state.navigation.localTargetZ =
        0


    state.navigation.targetYaw =
        0


    state.navigation.targetPitch =
        0

end


--------------------------------------------------
-- RESET SIGNAL FLAGS
--------------------------------------------------

local function resetSignals(
    state
)

    state.navigation.navigationTable =
        false


    state.navigation.navigationTableStatus =
        "OFF"


    state.navigation.navigationTarget =
        false


    state.navigation.navigationTargetStatus =
        "NO TARGET"


    state.navigation.altitudeSensor =
        false


    state.navigation.gimbalSensor =
        false


    state.navigation.velocitySensor =
        false


    state.navigation.velocitySensorX =
        false


    state.navigation.velocitySensorY =
        false


    state.navigation.velocitySensorZ =
        false

end


--------------------------------------------------
-- NAVIGATION TABLE UPDATE
--------------------------------------------------

local function updateNavigationTable(
    state
)

    local sensor =
        findFirstType(
            "navigation_table"
        )


    if not sensor then

        return

    end


    --------------------------------------------------
    -- HEADING
    --------------------------------------------------

    local headingOK,
    heading =
        safeCall(
            sensor,
            "getHeadingRad"
        )


    --------------------------------------------------
    -- ORIENTATION
    --------------------------------------------------

    local orientationOK,
    orientation =
        safeCall(
            sensor,
            "getOrientation"
        )


    --------------------------------------------------
    -- BASIC VALIDATION
    --------------------------------------------------

    if not headingOK
        or
        not isNumber(heading)
        or
        not orientationOK
        or
        type(orientation) ~= "table"
        or
        not isNumber(orientation[1])
        or
        not isNumber(orientation[2])
        or
        not isNumber(orientation[3])
        or
        not isNumber(orientation[4]) then

        return

    end


    --------------------------------------------------
    -- QUATERNION
    --------------------------------------------------

    local qx,
    qy,
    qz,
    qw =
        normalizeQuaternion(
            orientation[1],
            orientation[2],
            orientation[3],
            orientation[4]
        )


    state.navigation.navigationTable =
        true


    state.navigation.navigationTableStatus =
        "ONLINE"


    state.navigation.heading =
        heading


    state.navigation.orientation.x =
        qx


    state.navigation.orientation.y =
        qy


    state.navigation.orientation.z =
        qz


    state.navigation.orientation.w =
        qw


    --------------------------------------------------
    -- FORWARD VECTOR
    --------------------------------------------------

    local fx,
    fy,
    fz =
        bodyToWorld(
            0,
            0,
            1,
            qx,
            qy,
            qz,
            qw
        )


    fx,
    fy,
    fz =
        normalize(
            fx,
            fy,
            fz
        )


    state.navigation.forward.x =
        fx


    state.navigation.forward.y =
        fy


    state.navigation.forward.z =
        fz


    --------------------------------------------------
    -- NAVIGATION TABLE INTERNAL TARGET
    --------------------------------------------------

    local targetOK,
    hasTarget =
        safeCall(
            sensor,
            "hasTarget"
        )


    if targetOK then

        if hasTarget == true then

            state.navigation.navigationTarget =
                true


            state.navigation.navigationTargetStatus =
                "LOCKED"

        else

            state.navigation.navigationTarget =
                false


            state.navigation.navigationTargetStatus =
                "NO TARGET"

        end

    else

        state.navigation.navigationTarget =
            false


        state.navigation.navigationTargetStatus =
            "UNKNOWN"

    end


    --------------------------------------------------
    -- DIAGNOSTIC NAV TABLE VALUES
    --------------------------------------------------

    local ok,
    value =
        safeCall(
            sensor,
            "getBearingRad"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.bearing =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getRelativeAngleRad"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.relativeAngle =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getVerticalOffsetToTarget"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.elevation =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getDistanceToTarget"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.navTableDistance =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getClosureRate"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.closureRate =
            value

    end

end


--------------------------------------------------
-- ALTITUDE UPDATE
--------------------------------------------------

local function updateAltitude(
    state
)

    local sensor =
        findFirstType(
            "altitude_sensor"
        )


    if not sensor then
        return
    end


    local ok,
    altitude =
        safeCall(
            sensor,
            "getHeight"
        )


    if not ok
        or
        not isNumber(altitude) then

        return

    end


    state.navigation.altitudeSensor =
        true


    state.navigation.altitude =
        altitude


    --------------------------------------------------
    -- IMPORTANT:
    -- Altitude is treated as WORLD Y coordinate.
    --------------------------------------------------

    state.navigation.position.y =
        altitude


    --------------------------------------------------
    -- Vertical speed
    --------------------------------------------------

    ok,
    localValue =
        safeCall(
            sensor,
            "getVerticalSpeed"
        )


    if ok
        and
        isNumber(localValue) then

        state.navigation.verticalSpeed =
            localValue

    end


    --------------------------------------------------
    -- Air pressure
    --------------------------------------------------

    ok,
    localValue =
        safeCall(
            sensor,
            "getAirPressure"
        )


    if ok
        and
        isNumber(localValue) then

        state.navigation.airPressure =
            localValue

    end

end


--------------------------------------------------
-- GIMBAL UPDATE
--------------------------------------------------

local function updateGimbal(
    state
)

    local sensor =
        findFirstType(
            "gimbal_sensor"
        )


    if not sensor then
        return
    end


    local anglesOK,
    angles =
        safeCall(
            sensor,
            "getAnglesRad"
        )


    local ratesOK,
    rates =
        safeCall(
            sensor,
            "getAngularRatesRad"
        )


    local validAngles =
        anglesOK
        and
        type(angles) ==
        "table"


    local validRates =
        ratesOK
        and
        type(rates) ==
        "table"


    if not validAngles
        and
        not validRates then

        return

    end


    state.navigation.gimbalSensor =
        true


    --------------------------------------------------
    -- ANGLES
    --------------------------------------------------

    if validAngles then

        state.navigation.pitch =
            tonumber(
                angles[1]
            )
            or
            0


        state.navigation.roll =
            tonumber(
                angles[2]
            )
            or
            0

    end


    --------------------------------------------------
    -- RATES
    --------------------------------------------------

    if validRates then

        state.navigation.angularRateX =
            tonumber(
                rates[1]
            )
            or
            0


        state.navigation.angularRateY =
            tonumber(
                rates[2]
            )
            or
            0


        state.navigation.angularRateZ =
            tonumber(
                rates[3]
            )
            or
            0

    end


    --------------------------------------------------
    -- GRAVITY
    --------------------------------------------------

    local gravityOK,
    gravity =
        safeCall(
            sensor,
            "getGravity"
        )


    if gravityOK
        and
        type(gravity) ==
        "table" then

        state.navigation.gravityX =
            tonumber(
                gravity[1]
            )
            or
            0


        state.navigation.gravityY =
            tonumber(
                gravity[2]
            )
            or
            0


        state.navigation.gravityZ =
            tonumber(
                gravity[3]
            )
            or
            0


        state.navigation.gravityMagnitude =
            vectorLength(
                state.navigation.gravityX,
                state.navigation.gravityY,
                state.navigation.gravityZ
            )

    end


    --------------------------------------------------
    -- LINEAR ACCELERATION
    --------------------------------------------------

    local accelerationOK,
    acceleration =
        safeCall(
            sensor,
            "getLinearAcceleration"
        )


    if accelerationOK
        and
        type(acceleration) ==
        "table" then

        state.navigation.accelerationX =
            tonumber(
                acceleration[1]
            )
            or
            0


        state.navigation.accelerationY =
            tonumber(
                acceleration[2]
            )
            or
            0


        state.navigation.accelerationZ =
            tonumber(
                acceleration[3]
            )
            or
            0

    end

end


--------------------------------------------------
-- VELOCITY UPDATE
--------------------------------------------------

local function updateVelocity(
    state
)

    local sensor =
        findVelocitySensor()


    if not sensor then
        return
    end


    local ok,
    value =
        safeCall(
            sensor,
            "getVelocity"
        )


    if not ok
        or
        not isNumber(value) then

        return

    end


    local axisOK,
    axis =
        safeCall(
            sensor,
            "getAxis"
        )


    if not axisOK
        or
        type(axis) ~= "string" then

        return

    end


    axis =
        string.lower(
            axis
        )


    state.navigation.velocitySensor =
        true


    --------------------------------------------------
    -- Reset
    --------------------------------------------------

    state.navigation.bodyVelocity.x =
        0

    state.navigation.bodyVelocity.y =
        0

    state.navigation.bodyVelocity.z =
        0


    state.navigation.velocitySensorX =
        false

    state.navigation.velocitySensorY =
        false

    state.navigation.velocitySensorZ =
        false


    --------------------------------------------------
    -- Store measured axis
    --------------------------------------------------

    if axis == "x" then

        state.navigation.bodyVelocity.x =
            value


        state.navigation.velocitySensorX =
            true


    elseif axis == "y" then

        state.navigation.bodyVelocity.y =
            value


        state.navigation.velocitySensorY =
            true


    elseif axis == "z" then

        state.navigation.bodyVelocity.z =
            value


        state.navigation.velocitySensorZ =
            true

    else

        return

    end


    --------------------------------------------------
    -- BODY → WORLD
    --------------------------------------------------

    local q =
        state.navigation.orientation


    local vx,
    vy,
    vz =
        bodyToWorld(
            state.navigation.bodyVelocity.x,
            state.navigation.bodyVelocity.y,
            state.navigation.bodyVelocity.z,
            q.x,
            q.y,
            q.z,
            q.w
        )


    state.navigation.velocity.x =
        vx


    state.navigation.velocity.y =
        vy


    state.navigation.velocity.z =
        vz


    state.navigation.speed =
        vectorLength(
            vx,
            vy,
            vz
        )

end


--------------------------------------------------
-- MANUAL TARGET
--------------------------------------------------

local function updateTargetVector(
    state
)

    local target =
        state.target


    if type(target) ~= "table"
        or
        target.set ~= true then

        state.navigation.hasNavTarget =
            false


        state.navigation.targetDeltaX =
            0


        state.navigation.targetDeltaY =
            0


        state.navigation.targetDeltaZ =
            0


        state.navigation.targetDistance =
            0


        return

    end


    local position =
        state.navigation.position


    local dx =
        (
            tonumber(target.x)
            or
            0
        )
        -
        (
            tonumber(position.x)
            or
            0
        )


    local dy =
        (
            tonumber(target.y)
            or
            0
        )
        -
        (
            tonumber(position.y)
            or
            0
        )


    local dz =
        (
            tonumber(target.z)
            or
            0
        )
        -
        (
            tonumber(position.z)
            or
            0
        )


    local distance =
        vectorLength(
            dx,
            dy,
            dz
        )


    state.navigation.targetDeltaX =
        dx


    state.navigation.targetDeltaY =
        dy


    state.navigation.targetDeltaZ =
        dz


    state.navigation.targetDistance =
        distance


    state.navigation.hasNavTarget =
        true


    --------------------------------------------------
    -- Convert target to body coordinates
    --------------------------------------------------

    local q =
        state.navigation.orientation


    local lx,
    ly,
    lz =
        worldToBody(
            dx,
            dy,
            dz,
            q.x,
            q.y,
            q.z,
            q.w
        )


    lx,
    ly,
    lz =
        normalize(
            lx,
            ly,
            lz
        )


    state.navigation.localTargetX =
        lx


    state.navigation.localTargetY =
        ly


    state.navigation.localTargetZ =
        lz


    --------------------------------------------------
    -- TARGET YAW
    --------------------------------------------------

    if math.abs(lx) >
        0.000001
        or
        math.abs(lz) >
        0.000001 then

        state.navigation.targetYaw =
            math.atan(
                lx,
                lz
            )

    else

        state.navigation.targetYaw =
            0

    end


    --------------------------------------------------
    -- TARGET PITCH
    --------------------------------------------------

    state.navigation.targetPitch =
        math.atan(
            ly,
            math.sqrt(
                lx * lx +
                lz * lz
            )
        )

end


--------------------------------------------------
-- POSITION UPDATE
--------------------------------------------------

local function updatePosition(
    state,
    dt
)

    if dt <= 0
        or
        dt > 0.5 then

        return

    end


    local velocity =
        state.navigation.velocity


    --------------------------------------------------
    -- X
    --------------------------------------------------

    state.navigation.position.x =
        state.navigation.position.x +
        (
            tonumber(velocity.x)
            or
            0
        ) *
        dt


    --------------------------------------------------
    -- Z
    --------------------------------------------------

    state.navigation.position.z =
        state.navigation.position.z +
        (
            tonumber(velocity.z)
            or
            0
        ) *
        dt


    --------------------------------------------------
    -- Y
    --
    -- Y is already updated directly from the
    -- Altitude Sensor, so do not integrate it.
    --------------------------------------------------

    state.navigation.positionValid =
        state.navigation.navigationTable
        and
        state.navigation.altitudeSensor

end


--------------------------------------------------
-- OVERALL STATUS
--------------------------------------------------

local function updateStatus(
    state
)

    local n =
        state.navigation


    if n.navigationTable
        and
        n.altitudeSensor
        and
        n.gimbalSensor
        and
        n.velocitySensor then

        n.online =
            true


        n.status =
            "ONLINE"


    elseif n.navigationTable
        or
        n.altitudeSensor
        or
        n.gimbalSensor
        or
        n.velocitySensor then

        n.online =
            true


        n.status =
            "PARTIAL"


    else

        n.online =
            false


        n.status =
            "OFFLINE"

    end

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    initializeState(
        state
    )


    --------------------------------------------------
    -- IMPORTANT:
    -- Load start.cfg BEFORE the first target
    -- calculation.
    --------------------------------------------------

    initializePosition(
        state
    )


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    local previousTime =
        os.clock()


    while state.system
        and
        state.system.running do


        --------------------------------------------------
        -- RESET SIGNALS
        --------------------------------------------------

        resetSignals(
            state
        )


        --------------------------------------------------
        -- READ SENSORS
        --------------------------------------------------

        updateNavigationTable(
            state
        )


        updateAltitude(
            state
        )


        updateGimbal(
            state
        )


        updateVelocity(
            state
        )


        --------------------------------------------------
        -- TIME
        --------------------------------------------------

        local now =
            os.clock()


        local dt =
            now -
            previousTime


        previousTime =
            now


        if dt <= 0
            or
            dt > 0.5 then

            dt =
                UPDATE_INTERVAL

        end


        --------------------------------------------------
        -- UPDATE POSITION
        --------------------------------------------------

        updatePosition(
            state,
            dt
        )


        --------------------------------------------------
        -- MANUAL TARGET
        --------------------------------------------------

        updateTargetVector(
            state
        )


        --------------------------------------------------
        -- STATUS
        --------------------------------------------------

        updateStatus(
            state
        )


        --------------------------------------------------
        -- TIMESTAMP
        --------------------------------------------------

        state.navigation.lastUpdate =
            os.clock()


        state.navigation.error =
            nil


        sleep(
            UPDATE_INTERVAL
        )

    end


    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

    state.navigation.online =
        false


    state.navigation.status =
        "OFFLINE"


    state.navigation.navigationTable =
        false


    state.navigation.altitudeSensor =
        false


    state.navigation.gimbalSensor =
        false


    state.navigation.velocitySensor =
        false


    state.navigation.navigationTableStatus =
        "OFF"


    state.navigation.navigationTarget =
        false


    state.navigation.navigationTargetStatus =
        "NO TARGET"

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}