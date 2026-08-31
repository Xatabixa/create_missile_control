-- Missile Navigation System
-- CC:Tweaked
--
-- Navigation Table status and target status are separated.
--
-- NAV TABLE:
--   ONLINE / OFF
--
-- NAV TARGET:
--   LOCKED / NO TARGET
--
-- MANUAL TARGET:
--   SET / NOT SET
--
-- The target stored in target.cfg belongs to our
-- missile control system and is NOT the same thing
-- as the target configured inside Navigation Table.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05


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
-- FIND PERIPHERAL BY TYPE
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

                    return device, name

                end

            end

        end

    end


    return nil, nil

end


--------------------------------------------------
-- FIND ALL VELOCITY SENSORS
--------------------------------------------------

local function findVelocitySensors()

    local result = {}


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

                    table.insert(
                        result,
                        {
                            name = name,
                            device = device
                        }
                    )

                end

            end

        end

    end


    return result

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


    --------------------------------------------------
    -- NAVIGATION TABLE
    --------------------------------------------------

    state.navigation.navigationTable =
        false


    state.navigation.navigationTableStatus =
        "OFF"


    state.navigation.navigationTarget =
        false


    state.navigation.navigationTargetStatus =
        "NO TARGET"


    --------------------------------------------------
    -- OTHER SENSORS
    --------------------------------------------------

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
        state.navigation.position or
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
        state.navigation.velocity or
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


    --------------------------------------------------
    -- MANUAL TARGET VECTOR
    --------------------------------------------------

    state.navigation.hasNavTarget =
        false


    state.navigation.targetDeltaX =
        0


    state.navigation.targetDeltaY =
        0


    state.navigation.targetDeltaZ =
        0


    --------------------------------------------------
    -- ERROR
    --------------------------------------------------

    state.navigation.error =
        nil


    state.navigation.lastUpdate =
        0

end


--------------------------------------------------
-- RESET SIGNAL FLAGS
--------------------------------------------------

local function resetSignalFlags(
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
-- NAVIGATION TABLE
--------------------------------------------------

local function updateNavigationTable(
    state
)

    local sensor,
    name =
        findFirstType(
            "navigation_table"
        )


    --------------------------------------------------
    -- NOT CONNECTED
    --------------------------------------------------

    if not sensor then

        state.navigation.navigationTable =
            false


        state.navigation.navigationTableStatus =
            "OFF"


        state.navigation.navigationTarget =
            false


        state.navigation.navigationTargetStatus =
            "NO TARGET"


        return

    end


    --------------------------------------------------
    -- TEST DEVICE
    --
    -- We only need one valid core value to
    -- confirm that the device itself responds.
    --------------------------------------------------

    local headingOK,
    heading =
        safeCall(
            sensor,
            "getHeadingRad"
        )


    if not headingOK
        or
        not isNumber(heading) then

        state.navigation.navigationTable =
            false


        state.navigation.navigationTableStatus =
            "OFF"


        state.navigation.navigationTarget =
            false


        state.navigation.navigationTargetStatus =
            "NO SIGNAL"


        return

    end


    --------------------------------------------------
    -- DEVICE IS ONLINE
    --------------------------------------------------

    state.navigation.navigationTable =
        true


    state.navigation.navigationTableStatus =
        "ONLINE"


    state.navigation.heading =
        heading


    --------------------------------------------------
    -- CHECK NAVIGATION TABLE TARGET
    --------------------------------------------------

    local targetOK,
    hasTarget =
        safeCall(
            sensor,
            "hasTarget"
        )


    if targetOK
        and
        hasTarget == true then

        state.navigation.navigationTarget =
            true


        state.navigation.navigationTargetStatus =
            "LOCKED"


    elseif targetOK then

        state.navigation.navigationTarget =
            false


        state.navigation.navigationTargetStatus =
            "NO TARGET"


    else

        --------------------------------------------------
        -- Some versions may not expose hasTarget.
        -- Device itself is still considered ONLINE.
        --------------------------------------------------

        state.navigation.navigationTarget =
            false


        state.navigation.navigationTargetStatus =
            "UNKNOWN"

    end


    --------------------------------------------------
    -- BEARING
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


    --------------------------------------------------
    -- RELATIVE ANGLE
    --------------------------------------------------

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


    --------------------------------------------------
    -- VERTICAL OFFSET
    --------------------------------------------------

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


    --------------------------------------------------
    -- DISTANCE TO NAV TABLE TARGET
    --------------------------------------------------

    ok,
    value =
        safeCall(
            sensor,
            "getDistanceToTarget"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.distance =
            value

    end


    --------------------------------------------------
    -- CLOSURE RATE
    --------------------------------------------------

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
-- ALTITUDE SENSOR
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


    --------------------------------------------------
    -- HEIGHT
    --------------------------------------------------

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
    -- VERTICAL SPEED
    --------------------------------------------------

    ok,
    value =
        safeCall(
            sensor,
            "getVerticalSpeed"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.verticalSpeed =
            value

    end


    --------------------------------------------------
    -- PRESSURE
    --------------------------------------------------

    ok,
    value =
        safeCall(
            sensor,
            "getAirPressure"
        )


    if ok
        and
        isNumber(value) then

        state.navigation.airPressure =
            value

    end

end


--------------------------------------------------
-- GIMBAL SENSOR
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

    local anglesOK,
    angles =
        safeCall(
            sensor,
            "getAnglesRad"
        )


    --------------------------------------------------
    -- RATES
    --------------------------------------------------

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


        local gx =
            state.navigation.gravityX

        local gy =
            state.navigation.gravityY

        local gz =
            state.navigation.gravityZ


        state.navigation.gravityMagnitude =
            math.sqrt(
                gx * gx +
                gy * gy +
                gz * gz
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
-- VELOCITY SENSORS
--------------------------------------------------

local function updateVelocity(
    state
)

    local sensors =
        findVelocitySensors()


    if #sensors == 0 then

        return

    end


    local x = 0
    local y = 0
    local z = 0


    local gotX = false
    local gotY = false
    local gotZ = false


    for _, entry in ipairs(
        sensors
    ) do

        local ok,
        value =
            safeCall(
                entry.device,
                "getVelocity"
            )


        if ok
            and
            isNumber(value) then

            local axisOK,
            axis =
                safeCall(
                    entry.device,
                    "getAxis"
                )


            if axisOK
                and
                type(axis) ==
                "string" then

                axis =
                    string.lower(
                        axis
                    )

            end


            if axis == "x"
                and
                not gotX then

                x =
                    value

                gotX =
                    true


            elseif axis == "y"
                and
                not gotY then

                y =
                    value

                gotY =
                    true


            elseif axis == "z"
                and
                not gotZ then

                z =
                    value

                gotZ =
                    true

            end

        end

    end


    state.navigation.velocitySensorX =
        gotX


    state.navigation.velocitySensorY =
        gotY


    state.navigation.velocitySensorZ =
        gotZ


    if gotX
        or
        gotY
        or
        gotZ then

        state.navigation.velocitySensor =
            true

    end


    state.navigation.velocity.x =
        x


    state.navigation.velocity.y =
        y


    state.navigation.velocity.z =
        z


    state.navigation.speed =
        math.sqrt(
            x * x +
            y * y +
            z * z
        )

end


--------------------------------------------------
-- TARGET VECTOR
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


        return

    end


    local position =
        state.navigation.position


    local px =
        tonumber(position.x)
        or
        0


    local py =
        tonumber(position.y)
        or
        0


    local pz =
        tonumber(position.z)
        or
        0


    local tx =
        tonumber(target.x)
        or
        0


    local ty =
        tonumber(target.y)
        or
        0


    local tz =
        tonumber(target.z)
        or
        0


    state.navigation.targetDeltaX =
        tx - px


    state.navigation.targetDeltaY =
        ty - py


    state.navigation.targetDeltaZ =
        tz - pz


    state.navigation.hasNavTarget =
        true

end


--------------------------------------------------
-- POSITION
--------------------------------------------------

local function updatePosition(
    state,
    dt
)

    local velocity =
        state.navigation.velocity


    if type(velocity) ~=
        "table" then

        return

    end


    local vx =
        tonumber(
            velocity.x
        )
        or
        0


    local vz =
        tonumber(
            velocity.z
        )
        or
        0


    if dt > 0
        and
        dt < 0.5 then

        state.navigation.position.x =
            state.navigation.position.x +
            vx * dt


        state.navigation.position.z =
            state.navigation.position.z +
            vz * dt

    end


    --------------------------------------------------
    -- Y FROM ALTITUDE
    --------------------------------------------------

    if state.navigation.altitudeSensor then

        state.navigation.position.y =
            state.navigation.altitude -
            state.navigation.startAltitude

    end


    state.navigation.positionValid =
        state.navigation.altitudeSensor
        or
        state.navigation.velocitySensor

end


--------------------------------------------------
-- START POSITION
--------------------------------------------------

local function initializeStart(
    state
)

    state.navigation.startAltitude =
        tonumber(
            state.navigation.altitude
        )
        or
        0


    state.navigation.position =
        {
            x = 0,
            y = 0,
            z = 0
        }


    --------------------------------------------------
    -- Manual start position.
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

end


--------------------------------------------------
-- OVERALL STATUS
--------------------------------------------------

local function updateOverallStatus(
    state
)

    --------------------------------------------------
    -- FULL NAVIGATION
    --------------------------------------------------

    if state.navigation.navigationTable
        and
        state.navigation.gimbalSensor
        and
        state.navigation.velocitySensor
        and
        state.navigation.altitudeSensor then

        state.navigation.online =
            true


        state.navigation.status =
            "ONLINE"


    --------------------------------------------------
    -- PARTIAL
    --------------------------------------------------

    elseif state.navigation.navigationTable
        or
        state.navigation.gimbalSensor
        or
        state.navigation.velocitySensor
        or
        state.navigation.altitudeSensor then

        state.navigation.online =
            true


        state.navigation.status =
            "PARTIAL"


    --------------------------------------------------
    -- OFFLINE
    --------------------------------------------------

    else

        state.navigation.online =
            false


        state.navigation.status =
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
    -- INITIAL ALTITUDE
    --------------------------------------------------

    local altitudeSensor =
        findFirstType(
            "altitude_sensor"
        )


    if altitudeSensor then

        local ok,
        altitude =
            safeCall(
                altitudeSensor,
                "getHeight"
            )


        if ok
            and
            isNumber(altitude) then

            state.navigation.altitude =
                altitude

        end

    end


    --------------------------------------------------
    -- INITIAL POSITION
    --------------------------------------------------

    initializeStart(
        state
    )


    --------------------------------------------------
    -- TIMER
    --------------------------------------------------

    local lastTime =
        os.clock()


    --------------------------------------------------
    -- LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do


        --------------------------------------------------
        -- IMPORTANT:
        -- Every cycle starts OFF.
        --------------------------------------------------

        resetSignalFlags(
            state
        )


        --------------------------------------------------
        -- READ CURRENT DEVICES
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
            lastTime


        lastTime =
            now


        if dt <= 0
            or
            dt > 0.5 then

            dt =
                UPDATE_INTERVAL

        end


        --------------------------------------------------
        -- POSITION
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
        -- OVERALL
        --------------------------------------------------

        updateOverallStatus(
            state
        )


        --------------------------------------------------
        -- UPDATE TIME
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

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}