-- Missile Navigation System
-- CC:Tweaked
--
-- Uses:
--   Navigation Table
--   Gimbal Sensor
--   Altitude Sensor
--   Velocity Sensor
--
-- Manual target comes from state.target / target.cfg.
--
-- Navigation Table's internal target is NOT required.
--
-- Orientation is read as quaternion {x,y,z,w}.
-- Target vector is transformed into body coordinates.
--
-- This gives direct:
--   yaw error
--   pitch error
--
-- without mixing world bearing and heading.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- NUMBER CHECK
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
-- FIND FIRST TYPE
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
-- A single physical sensor may be visible
-- through multiple modems. We only use the
-- first valid one.
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
-- QUATERNION NORMALIZE
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
--
-- Quaternion:
--   q = x,y,z,w
--
-- Rotates body-space vector into world space.
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
-- ROTATE WORLD VECTOR INTO BODY FRAME
--------------------------------------------------
--
-- Inverse quaternion = conjugate
-- for normalized q.
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
-- FORWARD VECTOR
--------------------------------------------------
--
-- Local forward is +Z.
--------------------------------------------------

local function getForwardVector(
    qx,
    qy,
    qz,
    qw
)

    return rotateVector(
        0,
        0,
        1,
        qx,
        qy,
        qz,
        qw
    )

end


--------------------------------------------------
-- INITIAL STATE
--------------------------------------------------

local function initializeState(
    state
)

    state.navigation =
        state.navigation or {}


    state.navigation.online =
        false


    state.navigation.status =
        "OFFLINE"


    state.navigation.error =
        nil


    state.navigation.lastUpdate =
        0


    --------------------------------------------------
    -- DEVICES
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


    state.navigation.startAltitude =
        0


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
    -- ANGULAR RATE
    --------------------------------------------------

    state.navigation.angularRateX =
        0


    state.navigation.angularRateY =
        0


    state.navigation.angularRateZ =
        0


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    state.navigation.targetDeltaX =
        0


    state.navigation.targetDeltaY =
        0


    state.navigation.targetDeltaZ =
        0


    state.navigation.targetDistance =
        0


    state.navigation.hasNavTarget =
        false


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


    --------------------------------------------------
    -- NAV TABLE DATA
    --------------------------------------------------

    state.navigation.bearing =
        0


    state.navigation.relativeAngle =
        0


    state.navigation.elevation =
        0


    state.navigation.distance =
        0


    state.navigation.closureRate =
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
-- READ NAVIGATION TABLE
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
    -- DEVICE SIGNAL
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
    -- NORMALIZE QUATERNION
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


    --------------------------------------------------
    -- STORE
    --------------------------------------------------

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
    -- FORWARD
    --------------------------------------------------

    local fx,
    fy,
    fz =
        getForwardVector(
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
    -- NAV TABLE INTERNAL TARGET
    --
    -- This is only diagnostic information.
    -- It is NOT our manual target.
    --------------------------------------------------

    local targetOK,
    hasTarget =
        safeCall(
            sensor,
            "hasTarget"
        )


    if targetOK then

        state.navigation.navigationTarget =
            hasTarget == true


        if hasTarget == true then

            state.navigation.navigationTargetStatus =
                "LOCKED"

        else

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
    -- NAV TABLE TARGET DATA
    --------------------------------------------------

    local ok,
    value =
        safeCall(
            sensor,
            "getBearingRad"
        )


    if ok and isNumber(value) then

        state.navigation.bearing =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getRelativeAngleRad"
        )


    if ok and isNumber(value) then

        state.navigation.relativeAngle =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getVerticalOffsetToTarget"
        )


    if ok and isNumber(value) then

        state.navigation.elevation =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getDistanceToTarget"
        )


    if ok and isNumber(value) then

        state.navigation.navTableDistance =
            value

    end


    ok,
    value =
        safeCall(
            sensor,
            "getClosureRate"
        )


    if ok and isNumber(value) then

        state.navigation.closureRate =
            value

    end

end


--------------------------------------------------
-- ALTITUDE
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
    -- OPTIONAL VALUES
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
-- GIMBAL
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


    --------------------------------------------------
    -- ANGLES
    --------------------------------------------------

    local angleOK,
    angles =
        safeCall(
            sensor,
            "getAnglesRad"
        )


    --------------------------------------------------
    -- ANGULAR RATES
    --------------------------------------------------

    local rateOK,
    rates =
        safeCall(
            sensor,
            "getAngularRatesRad"
        )


    if not angleOK
        and
        not rateOK then

        return

    end


    state.navigation.gimbalSensor =
        true


    --------------------------------------------------
    -- ANGLES
    --------------------------------------------------

    if angleOK
        and
        type(angles) ==
        "table" then

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

    if rateOK
        and
        type(rates) ==
        "table" then

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
    -- ACCELERATION
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
-- VELOCITY
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


    --------------------------------------------------
    -- ONLINE
    --------------------------------------------------

    state.navigation.velocitySensor =
        true


    --------------------------------------------------
    -- RESET BODY VELOCITY
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
    -- BODY AXIS
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

    end


    --------------------------------------------------
    -- BODY → WORLD
    --------------------------------------------------

    local bv =
        state.navigation.bodyVelocity


    local q =
        state.navigation.orientation


    local vx,
    vy,
    vz =
        rotateVector(
            bv.x,
            bv.y,
            bv.z,
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
-- MANUAL TARGET VECTOR
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


        state.navigation.distance =
            0


        return

    end


    local position =
        state.navigation.position


    local dx =
        (tonumber(target.x) or 0) -
        (tonumber(position.x) or 0)


    local dy =
        (tonumber(target.y) or 0) -
        (tonumber(position.y) or 0)


    local dz =
        (tonumber(target.z) or 0) -
        (tonumber(position.z) or 0)


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


    state.navigation.distance =
        distance


    state.navigation.hasNavTarget =
        true


    --------------------------------------------------
    -- WORLD TARGET → BODY TARGET
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
    -- DIRECT TARGET ANGLES
    --------------------------------------------------

    if math.abs(lx) > 0.000001
        or
        math.abs(lz) > 0.000001 then

        state.navigation.targetYaw =
            math.atan(
                lx,
                lz
            )

    else

        state.navigation.targetYaw =
            0

    end


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
-- POSITION
--------------------------------------------------

local function updatePosition(
    state,
    dt
)

    local v =
        state.navigation.velocity


    if dt <= 0
        or
        dt > 0.5 then

        return

    end


    state.navigation.position.x =
        state.navigation.position.x +
        v.x * dt


    state.navigation.position.z =
        state.navigation.position.z +
        v.z * dt


    --------------------------------------------------
    -- ALTITUDE
    --------------------------------------------------

    if state.navigation.altitudeSensor then

        state.navigation.position.y =
            state.navigation.altitude

    end


    state.navigation.positionValid =
        true

end


--------------------------------------------------
-- START POSITION
--------------------------------------------------

local function initializeStart(
    state
)

    state.navigation.position =
        {
            x = 0,
            y = 0,
            z = 0
        }


    --------------------------------------------------
    -- Use saved start coordinates when available.
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

    end


    state.navigation.startAltitude =
        state.navigation.position.y

end


--------------------------------------------------
-- UPDATE OVERALL STATUS
--------------------------------------------------

local function updateStatus(
    state
)

    local nav =
        state.navigation


    if nav.navigationTable
        and
        nav.altitudeSensor
        and
        nav.gimbalSensor
        and
        nav.velocitySensor then

        nav.online =
            true

        nav.status =
            "ONLINE"


    elseif nav.navigationTable
        or
        nav.altitudeSensor
        or
        nav.gimbalSensor
        or
        nav.velocitySensor then

        nav.online =
            true

        nav.status =
            "PARTIAL"


    else

        nav.online =
            false

        nav.status =
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
    -- INITIALIZE POSITION
    --------------------------------------------------

    initializeStart(
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
        -- RESET SIGNAL FLAGS
        --------------------------------------------------

        resetSignals(
            state
        )


        --------------------------------------------------
        -- CURRENT TIME
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
        -- SENSORS
        --------------------------------------------------

        updateNavigationTable(
            state
        )


        updateGimbal(
            state
        )


        updateAltitude(
            state
        )


        updateVelocity(
            state
        )


        --------------------------------------------------
        -- POSITION
        --------------------------------------------------

        updatePosition(
            state,
            dt
        )


        --------------------------------------------------
        -- TARGET
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
        -- ERROR
        --------------------------------------------------

        state.navigation.error =
            nil


        state.navigation.lastUpdate =
            os.clock()


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

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}