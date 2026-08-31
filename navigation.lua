-- Missile Navigation System
-- CC:Tweaked
--
-- Uses:
--   Navigation Table
--   Gimbal Sensor
--   Altitude Sensor
--   Velocity Sensor
--
-- Manual target comes from state.target.
-- Start position comes from start.cfg.
--
-- Navigation Table orientation is converted to
-- a world-space forward vector.
--
-- Target direction is compared directly with
-- the forward vector. No bearing-heading subtraction
-- is used for manual guidance.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05
local START_FILE = "start.cfg"


--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function isNumber(v)
    return type(v) == "number" and v == v
end


--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function safeCall(device, method, ...)
    if not device then
        return false, nil
    end

    local fn = device[method]

    if type(fn) ~= "function" then
        return false, nil
    end

    local ok, a, b, c, d =
        pcall(fn, ...)

    if not ok then
        return false, nil
    end

    return true, a, b, c, d
end


--------------------------------------------------
-- FIND FIRST DEVICE
--------------------------------------------------

local function findFirstType(pType)

    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            pType
        ) then

            if peripheral.isPresent(name) then

                local device =
                    peripheral.wrap(name)

                if device then
                    return device, name
                end

            end

        end

    end

    return nil, nil
end


--------------------------------------------------
-- FIND VELOCITY SENSOR
--
-- The same physical sensor can appear through
-- multiple modems. Only the first valid one is used.
--------------------------------------------------

local function findVelocitySensor()

    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            "velocity_sensor"
        ) then

            if peripheral.isPresent(name) then

                local device =
                    peripheral.wrap(name)

                if device then

                    return device, name

                end

            end

        end

    end

    return nil, nil
end


--------------------------------------------------
-- VECTOR LENGTH
--------------------------------------------------

local function vectorLength(x, y, z)

    return math.sqrt(
        x * x +
        y * y +
        z * z
    )

end


--------------------------------------------------
-- NORMALIZE VECTOR
--------------------------------------------------

local function normalize(x, y, z)

    local length =
        vectorLength(x, y, z)

    if length < 0.000001 then
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

    if length < 0.000001 then
        return 0, 0, 0, 1
    end

    return
        x / length,
        y / length,
        z / length,
        w / length

end


--------------------------------------------------
-- QUATERNION ROTATION
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
        2 * (
            qy * z -
            qz * y
        )

    local ty =
        2 * (
            qz * x -
            qx * z
        )

    local tz =
        2 * (
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
-- START POSITION FILE
--------------------------------------------------

local function loadStartFile(state)

    if type(state.startPosition) == "table"
        and
        state.startPosition.set == true then

        return
    end

    if not fs.exists(START_FILE) then
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

    local data =
        textutils.unserialize(
            file.readAll()
        )

    file.close()

    if type(data) ~= "table" then
        return
    end

    state.startPosition =
        state.startPosition
        or
        {}

    state.startPosition.x =
        tonumber(data.x)
        or
        0

    state.startPosition.y =
        tonumber(data.y)
        or
        0

    state.startPosition.z =
        tonumber(data.z)
        or
        0

    state.startPosition.set =
        data.set == true

end


--------------------------------------------------
-- INITIAL STATE
--------------------------------------------------

local function initializeState(state)

    state.navigation =
        state.navigation
        or
        {}

    local n =
        state.navigation

    n.online = false
    n.status = "OFFLINE"

    n.navigationTable = false
    n.navigationTableStatus = "OFF"

    n.navigationTarget = false
    n.navigationTargetStatus = "NO TARGET"

    n.altitudeSensor = false
    n.gimbalSensor = false
    n.velocitySensor = false

    n.velocitySensorX = false
    n.velocitySensorY = false
    n.velocitySensorZ = false

    n.position = {
        x = 0,
        y = 0,
        z = 0
    }

    n.positionValid = false

    n.velocity = {
        x = 0,
        y = 0,
        z = 0
    }

    n.bodyVelocity = {
        x = 0,
        y = 0,
        z = 0
    }

    n.speed = 0

    n.altitude = 0
    n.verticalSpeed = 0
    n.airPressure = 0

    n.heading = 0
    n.pitch = 0
    n.roll = 0

    n.orientation = {
        x = 0,
        y = 0,
        z = 0,
        w = 1
    }

    n.forward = {
        x = 0,
        y = 0,
        z = 1
    }

    n.angularRateX = 0
    n.angularRateY = 0
    n.angularRateZ = 0

    n.accelerationX = 0
    n.accelerationY = 0
    n.accelerationZ = 0

    n.gravityX = 0
    n.gravityY = 0
    n.gravityZ = 0
    n.gravityMagnitude = 0

    n.bearing = 0
    n.relativeAngle = 0
    n.elevation = 0
    n.navTableDistance = 0
    n.closureRate = 0

    n.hasNavTarget = false

    n.targetDeltaX = 0
    n.targetDeltaY = 0
    n.targetDeltaZ = 0
    n.targetDistance = 0

    n.localTargetX = 0
    n.localTargetY = 0
    n.localTargetZ = 0

    n.targetYaw = 0
    n.targetPitch = 0

    n.lastUpdate = 0
    n.error = nil

end


--------------------------------------------------
-- RESET SIGNAL FLAGS
--------------------------------------------------

local function resetSignals(state)

    local n =
        state.navigation

    n.navigationTable = false
    n.navigationTableStatus = "OFF"

    n.navigationTarget = false
    n.navigationTargetStatus = "NO TARGET"

    n.altitudeSensor = false
    n.gimbalSensor = false
    n.velocitySensor = false

    n.velocitySensorX = false
    n.velocitySensorY = false
    n.velocitySensorZ = false

end


--------------------------------------------------
-- NAVIGATION TABLE
--------------------------------------------------

local function updateNavigationTable(state)

    local sensor =
        findFirstType(
            "navigation_table"
        )

    local n =
        state.navigation

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


    n.navigationTable = true
    n.navigationTableStatus = "ONLINE"

    n.heading = heading


    n.orientation.x = qx
    n.orientation.y = qy
    n.orientation.z = qz
    n.orientation.w = qw


    --------------------------------------------------
    -- FORWARD VECTOR
    --
    -- Local +Z is the forward direction.
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


    n.forward.x = fx
    n.forward.y = fy
    n.forward.z = fz


    --------------------------------------------------
    -- INTERNAL NAV TABLE TARGET
    --------------------------------------------------

    local targetOK,
    hasTarget =
        safeCall(
            sensor,
            "hasTarget"
        )


    if targetOK then

        n.navigationTarget =
            hasTarget == true


        if hasTarget == true then

            n.navigationTargetStatus =
                "LOCKED"

        else

            n.navigationTargetStatus =
                "NO TARGET"

        end

    else

        n.navigationTargetStatus =
            "UNKNOWN"

    end


    --------------------------------------------------
    -- OPTIONAL NAV TABLE DATA
    --------------------------------------------------

    local ok,
    value


    ok,
    value =
        safeCall(
            sensor,
            "getBearingRad"
        )

    if ok and isNumber(value) then
        n.bearing = value
    end


    ok,
    value =
        safeCall(
            sensor,
            "getRelativeAngleRad"
        )

    if ok and isNumber(value) then
        n.relativeAngle = value
    end


    ok,
    value =
        safeCall(
            sensor,
            "getVerticalOffsetToTarget"
        )

    if ok and isNumber(value) then
        n.elevation = value
    end


    ok,
    value =
        safeCall(
            sensor,
            "getDistanceToTarget"
        )

    if ok and isNumber(value) then
        n.navTableDistance = value
    end


    ok,
    value =
        safeCall(
            sensor,
            "getClosureRate"
        )

    if ok and isNumber(value) then
        n.closureRate = value
    end

end


--------------------------------------------------
-- ALTITUDE SENSOR
--------------------------------------------------

local function updateAltitude(state)

    local sensor =
        findFirstType(
            "altitude_sensor"
        )

    local n =
        state.navigation

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


    n.altitudeSensor = true

    n.altitude = altitude

    --------------------------------------------------
    -- Altitude sensor supplies world Y.
    --------------------------------------------------

    n.position.y = altitude


    localValue =
        nil


    ok,
    localValue =
        safeCall(
            sensor,
            "getVerticalSpeed"
        )


    if ok
        and
        isNumber(localValue) then

        n.verticalSpeed =
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

        n.airPressure =
            localValue

    end

end


--------------------------------------------------
-- GIMBAL SENSOR
--------------------------------------------------

local function updateGimbal(state)

    local sensor =
        findFirstType(
            "gimbal_sensor"
        )

    local n =
        state.navigation

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


    if not anglesOK
        and
        not ratesOK then

        return
    end


    n.gimbalSensor = true


    --------------------------------------------------
    -- ANGLES
    --------------------------------------------------

    if anglesOK
        and
        type(angles) ==
        "table" then

        n.pitch =
            tonumber(
                angles[1]
            )
            or
            0


        n.roll =
            tonumber(
                angles[2]
            )
            or
            0

    end


    --------------------------------------------------
    -- ANGULAR RATES
    --------------------------------------------------

    if ratesOK
        and
        type(rates) ==
        "table" then

        n.angularRateX =
            tonumber(
                rates[1]
            )
            or
            0


        n.angularRateY =
            tonumber(
                rates[2]
            )
            or
            0


        n.angularRateZ =
            tonumber(
                rates[3]
            )
            or
            0

    end


    --------------------------------------------------
    -- GRAVITY
    --------------------------------------------------

    local okGravity,
    gravity =
        safeCall(
            sensor,
            "getGravity"
        )


    if okGravity
        and
        type(gravity) ==
        "table" then

        n.gravityX =
            tonumber(
                gravity[1]
            )
            or
            0


        n.gravityY =
            tonumber(
                gravity[2]
            )
            or
            0


        n.gravityZ =
            tonumber(
                gravity[3]
            )
            or
            0


        n.gravityMagnitude =
            vectorLength(
                n.gravityX,
                n.gravityY,
                n.gravityZ
            )

    end


    --------------------------------------------------
    -- ACCELERATION
    --------------------------------------------------

    local okAcceleration,
    acceleration =
        safeCall(
            sensor,
            "getLinearAcceleration"
        )


    if okAcceleration
        and
        type(acceleration) ==
        "table" then

        n.accelerationX =
            tonumber(
                acceleration[1]
            )
            or
            0


        n.accelerationY =
            tonumber(
                acceleration[2]
            )
            or
            0


        n.accelerationZ =
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

local function updateVelocity(state)

    local sensor =
        findVelocitySensor()

    local n =
        state.navigation

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


    n.velocitySensor =
        true


    n.velocitySensorX =
        false


    n.velocitySensorY =
        false


    n.velocitySensorZ =
        false


    n.bodyVelocity.x = 0
    n.bodyVelocity.y = 0
    n.bodyVelocity.z = 0


    if axis == "x" then

        n.bodyVelocity.x =
            value

        n.velocitySensorX =
            true


    elseif axis == "y" then

        n.bodyVelocity.y =
            value

        n.velocitySensorY =
            true


    elseif axis == "z" then

        n.bodyVelocity.z =
            value

        n.velocitySensorZ =
            true


    else

        return

    end


    --------------------------------------------------
    -- BODY → WORLD
    --------------------------------------------------

    local q =
        n.orientation


    local vx,
    vy,
    vz =
        bodyToWorld(
            n.bodyVelocity.x,
            n.bodyVelocity.y,
            n.bodyVelocity.z,
            q.x,
            q.y,
            q.z,
            q.w
        )


    n.velocity.x = vx
    n.velocity.y = vy
    n.velocity.z = vz


    n.speed =
        vectorLength(
            vx,
            vy,
            vz
        )

end


--------------------------------------------------
-- TARGET VECTOR
--------------------------------------------------

local function updateTargetVector(state)

    local n =
        state.navigation

    local target =
        state.target


    if type(target) ~= "table"
        or
        target.set ~= true then

        n.hasNavTarget = false

        n.targetDeltaX = 0
        n.targetDeltaY = 0
        n.targetDeltaZ = 0

        n.targetDistance = 0

        n.localTargetX = 0
        n.localTargetY = 0
        n.localTargetZ = 0

        n.targetYaw = 0
        n.targetPitch = 0

        return
    end


    --------------------------------------------------
    -- WORLD TARGET VECTOR
    --------------------------------------------------

    local dx =
        (
            tonumber(target.x)
            or
            0
        )
        -
        (
            tonumber(n.position.x)
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
            tonumber(n.position.y)
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
            tonumber(n.position.z)
            or
            0
        )


    local distance =
        vectorLength(
            dx,
            dy,
            dz
        )


    n.targetDeltaX = dx
    n.targetDeltaY = dy
    n.targetDeltaZ = dz

    n.targetDistance =
        distance


    n.hasNavTarget =
        true


    --------------------------------------------------
    -- NORMALIZED TARGET
    --------------------------------------------------

    local tx,
    ty,
    tz =
        normalize(
            dx,
            dy,
            dz
        )


    --------------------------------------------------
    -- WORLD → BODY
    --
    -- This is DIAGNOSTIC ONLY.
    -- Guidance does NOT use the old local-angle
    -- calculation anymore.
    --------------------------------------------------

    local q =
        n.orientation


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


    n.localTargetX =
        lx


    n.localTargetY =
        ly


    n.localTargetZ =
        lz


    --------------------------------------------------
    -- TARGET ANGLE FROM WORLD TARGET VECTOR
    --
    -- Diagnostic values only.
    --------------------------------------------------

    local horizontal =
        math.sqrt(
            tx * tx +
            tz * tz
        )


    if horizontal >
        0.000001 then

        n.targetYaw =
            math.atan(
                tx,
                tz
            )

    else

        n.targetYaw =
            0

    end


    n.targetPitch =
        math.atan(
            ty,
            horizontal
        )

end


--------------------------------------------------
-- POSITION UPDATE
--------------------------------------------------

local function updatePosition(
    state,
    dt
)

    local n =
        state.navigation


    if dt <= 0
        or
        dt > 0.5 then

        return

    end


    --------------------------------------------------
    -- X
    --------------------------------------------------

    n.position.x =
        n.position.x +
        (
            tonumber(
                n.velocity.x
            )
            or
            0
        ) *
        dt


    --------------------------------------------------
    -- Z
    --------------------------------------------------

    n.position.z =
        n.position.z +
        (
            tonumber(
                n.velocity.z
            )
            or
            0
        ) *
        dt


    --------------------------------------------------
    -- Y comes directly from Altitude Sensor.
    --------------------------------------------------

    if n.altitudeSensor then

        n.position.y =
            n.altitude

    end


    n.positionValid =
        n.navigationTable
        and
        n.altitudeSensor

end


--------------------------------------------------
-- OVERALL STATUS
--------------------------------------------------

local function updateStatus(state)

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
    -- LOAD START BEFORE FIRST CALCULATION
    --------------------------------------------------

    loadStartFile(
        state
    )


    --------------------------------------------------
    -- INITIAL POSITION
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


    --------------------------------------------------
    -- LOOP
    --------------------------------------------------

    local previousTime =
        os.clock()


    while state.system
        and
        state.system.running do


        --------------------------------------------------
        -- RESET DEVICE STATUS
        --------------------------------------------------

        resetSignals(
            state
        )


        --------------------------------------------------
        -- DT
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
        -- DEVICES
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

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}