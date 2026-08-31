-- Missile Navigation System
-- Create: Avionics / Create: Aeronautics
-- CC:Tweaked
--
-- Device status is based on REAL DATA SIGNAL,
-- not just peripheral existence.
--
-- ONLINE = peripheral exists AND sensor methods
-- successfully return valid data.
--
-- OFFLINE = no peripheral or no valid signal.

--------------------------------------------------
-- PERIPHERALS
--------------------------------------------------

local navigationTable =
    peripheral.find("navigation_table")

local altitudeSensor =
    peripheral.find("altitude_sensor")

local gimbalSensor =
    peripheral.find("gimbal_sensor")


--------------------------------------------------
-- VELOCITY SENSORS
--------------------------------------------------

local velocitySensors = {}


for _, name in ipairs(
    peripheral.getNames()
) do

    if peripheral.getType(name) ==
        "velocity_sensor" then

        local sensor =
            peripheral.wrap(name)

        if sensor then

            table.insert(
                velocitySensors,
                {
                    name = name,
                    device = sensor
                }
            )

        end

    end

end


--------------------------------------------------
-- SIGNAL HELPERS
--------------------------------------------------

local function numeric(
    value
)

    return type(value) == "number"
        and value == value

end


--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function safeCall(
    object,
    method,
    ...
)

    if not object then

        return false,
            nil

    end


    local fn =
        object[method]


    if type(fn) ~= "function" then

        return false,
            nil

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

        return false,
            nil

    end


    return true,
        a,
        b,
        c,
        d

end


--------------------------------------------------
-- SIGNAL COUNTERS
--------------------------------------------------

local navigationFailures = 0

local altitudeFailures = 0

local gimbalFailures = 0

local velocityFailures = 0


local MAX_FAILURES = 10


--------------------------------------------------
-- SIGNAL STATUS
--------------------------------------------------

local function updateSignalState(
    state
)

    --------------------------------------------------
    -- NAVIGATION TABLE
    --------------------------------------------------

    if navigationTable then

        local ok1,
        heading =
            safeCall(
                navigationTable,
                "getHeadingRad"
            )


        local ok2,
        bearing =
            safeCall(
                navigationTable,
                "getBearingRad"
            )


        if ok1
            and ok2
            and numeric(heading)
            and numeric(bearing) then

            navigationFailures =
                0

        else

            navigationFailures =
                navigationFailures + 1

        end

    else

        navigationFailures =
            MAX_FAILURES

    end


    --------------------------------------------------
    -- ALTITUDE SENSOR
    --------------------------------------------------

    if altitudeSensor then

        local ok,
        altitude =
            safeCall(
                altitudeSensor,
                "getHeight"
            )


        if ok
            and numeric(altitude) then

            altitudeFailures =
                0

        else

            altitudeFailures =
                altitudeFailures + 1

        end

    else

        altitudeFailures =
            MAX_FAILURES

    end


    --------------------------------------------------
    -- GIMBAL SENSOR
    --------------------------------------------------

    if gimbalSensor then

        local ok,
        angles =
            safeCall(
                gimbalSensor,
                "getAnglesRad"
            )


        local okRates,
        rates =
            safeCall(
                gimbalSensor,
                "getAngularRatesRad"
            )


        local validAngles =
            ok
            and
            type(angles) == "table"


        local validRates =
            okRates
            and
            type(rates) == "table"


        if validAngles
            or
            validRates then

            gimbalFailures =
                0

        else

            gimbalFailures =
                gimbalFailures + 1

        end

    else

        gimbalFailures =
            MAX_FAILURES

    end


    --------------------------------------------------
    -- VELOCITY
    --------------------------------------------------

    local velocityGood =
        false


    for _, entry in ipairs(
        velocitySensors
    ) do

        local ok,
        value =
            safeCall(
                entry.device,
                "getVelocity"
            )


        if ok
            and
            numeric(value) then

            velocityGood =
                true

            break

        end

    end


    if velocityGood then

        velocityFailures =
            0

    else

        velocityFailures =
            velocityFailures + 1

    end


    --------------------------------------------------
    -- PUBLISH SIGNAL STATE
    --------------------------------------------------

    state.navigation.navigationTable =
        navigationFailures <
        MAX_FAILURES


    state.navigation.altitudeSensor =
        altitudeFailures <
        MAX_FAILURES


    state.navigation.gimbalSensor =
        gimbalFailures <
        MAX_FAILURES


    state.navigation.velocitySensor =
        velocityFailures <
        MAX_FAILURES


    --------------------------------------------------
    -- OVERALL NAVIGATION
    --------------------------------------------------

    state.navigation.online =
        state.navigation.navigationTable
        or
        state.navigation.altitudeSensor
        or
        state.navigation.gimbalSensor
        or
        state.navigation.velocitySensor


    if state.navigation.online then

        state.navigation.status =
            "ONLINE"

    else

        state.navigation.status =
            "OFFLINE"

    end

end


--------------------------------------------------
-- UPDATE NAVIGATION TABLE
--------------------------------------------------

local function updateNavigationTable(
    state
)

    if not navigationTable then

        return

    end


    --------------------------------------------------
    -- HEADING
    --------------------------------------------------

    local ok,
    heading =
        safeCall(
            navigationTable,
            "getHeadingRad"
        )


    if ok
        and
        numeric(heading) then

        state.navigation.heading =
            heading

    end


    --------------------------------------------------
    -- BEARING
    --------------------------------------------------

    ok,
    value =
        safeCall(
            navigationTable,
            "getBearingRad"
        )


    if ok
        and
        numeric(value) then

        state.navigation.bearing =
            value

    end


    --------------------------------------------------
    -- RELATIVE ANGLE
    --------------------------------------------------

    ok,
    value =
        safeCall(
            navigationTable,
            "getRelativeAngleRad"
        )


    if ok
        and
        numeric(value) then

        state.navigation.relativeAngle =
            value

    end


    --------------------------------------------------
    -- ELEVATION
    --------------------------------------------------

    ok,
    value =
        safeCall(
            navigationTable,
            "getVerticalOffsetToTarget"
        )


    if ok
        and
        numeric(value) then

        state.navigation.elevation =
            value

    end


    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    ok,
    value =
        safeCall(
            navigationTable,
            "getDistanceToTarget"
        )


    if ok
        and
        numeric(value) then

        state.navigation.distance =
            value

    end


    --------------------------------------------------
    -- CLOSURE
    --------------------------------------------------

    ok,
    value =
        safeCall(
            navigationTable,
            "getClosureRate"
        )


    if ok
        and
        numeric(value) then

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

    if not altitudeSensor then

        return

    end


    --------------------------------------------------
    -- HEIGHT
    --------------------------------------------------

    local ok,
    altitude =
        safeCall(
            altitudeSensor,
            "getHeight"
        )


    if ok
        and
        numeric(altitude) then

        state.navigation.altitude =
            altitude

    end


    --------------------------------------------------
    -- VERTICAL SPEED
    --------------------------------------------------

    ok,
    value =
        safeCall(
            altitudeSensor,
            "getVerticalSpeed"
        )


    if ok
        and
        numeric(value) then

        state.navigation.verticalSpeed =
            value

    end


    --------------------------------------------------
    -- PRESSURE
    --------------------------------------------------

    ok,
    value =
        safeCall(
            altitudeSensor,
            "getAirPressure"
        )


    if ok
        and
        numeric(value) then

        state.navigation.airPressure =
            value

    end

end


--------------------------------------------------
-- VELOCITY
--------------------------------------------------

local function updateVelocity(
    state
)

    local worldX = 0
    local worldY = 0
    local worldZ = 0

    local found =
        false


    --------------------------------------------------
    -- READ SENSORS
    --------------------------------------------------

    for index, entry in ipairs(
        velocitySensors
    ) do

        local ok,
        value =
            safeCall(
                entry.device,
                "getVelocity"
            )


        if ok
            and
            numeric(value) then

            --------------------------------------------------
            -- Preserve original axis assignment.
            --
            -- First valid velocity sensor is treated
            -- as X unless its metadata provides an axis.
            --------------------------------------------------

            local axis =
                nil


            local axisOK,
            axisValue =
                safeCall(
                    entry.device,
                    "getAxis"
                )


            if axisOK
                and
                type(axisValue) ==
                "string" then

                axis =
                    string.lower(
                        axisValue
                    )

            end


            if axis == "x" then

                worldX =
                    value

                found =
                    true

            elseif axis == "y" then

                worldY =
                    value

                found =
                    true

            elseif axis == "z" then

                worldZ =
                    value

                found =
                    true

            else

                --------------------------------------------------
                -- Fallback:
                -- preserve sensor order.
                --------------------------------------------------

                if index == 1 then

                    worldX =
                        value

                elseif index == 2 then

                    worldY =
                        value

                elseif index == 3 then

                    worldZ =
                        value

                end


                found =
                    true

            end

        end

    end


    --------------------------------------------------
    -- SAVE
    --------------------------------------------------

    if found then

        state.navigation.velocity.x =
            worldX

        state.navigation.velocity.y =
            worldY

        state.navigation.velocity.z =
            worldZ


        state.navigation.speed =
            math.sqrt(
                worldX * worldX +
                worldY * worldY +
                worldZ * worldZ
            )

    end

end


--------------------------------------------------
-- GIMBAL
--------------------------------------------------

local function updateGimbal(
    state
)

    if not gimbalSensor then

        return

    end


    --------------------------------------------------
    -- ANGLES
    --------------------------------------------------

    local ok,
    angles =
        safeCall(
            gimbalSensor,
            "getAnglesRad"
        )


    if ok
        and
        type(angles) ==
        "table" then

        state.navigation.pitch =
            tonumber(
                angles[1]
            )
            or 0


        state.navigation.roll =
            tonumber(
                angles[2]
            )
            or 0

    end


    --------------------------------------------------
    -- ANGULAR RATES
    --------------------------------------------------

    ok,
    localRates =
        safeCall(
            gimbalSensor,
            "getAngularRatesRad"
        )


    if ok
        and
        type(localRates) ==
        "table" then

        state.navigation.angularRateX =
            tonumber(
                localRates[1]
            )
            or 0


        state.navigation.angularRateY =
            tonumber(
                localRates[2]
            )
            or 0


        state.navigation.angularRateZ =
            tonumber(
                localRates[3]
            )
            or 0

    end


    --------------------------------------------------
    -- GRAVITY
    --------------------------------------------------

    ok,
    localGravity =
        safeCall(
            gimbalSensor,
            "getGravity"
        )


    if ok
        and
        type(localGravity) ==
        "table" then

        state.navigation.gravityX =
            tonumber(
                localGravity[1]
            )
            or 0


        state.navigation.gravityY =
            tonumber(
                localGravity[2]
            )
            or 0


        state.navigation.gravityZ =
            tonumber(
                localGravity[3]
            )
            or 0


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
    -- LINEAR ACCELERATION
    --------------------------------------------------

    ok,
    localAcceleration =
        safeCall(
            gimbalSensor,
            "getLinearAcceleration"
        )


    if ok
        and
        type(localAcceleration) ==
        "table" then

        state.navigation.accelerationX =
            tonumber(
                localAcceleration[1]
            )
            or 0


        state.navigation.accelerationY =
            tonumber(
                localAcceleration[2]
            )
            or 0


        state.navigation.accelerationZ =
            tonumber(
                localAcceleration[3]
            )
            or 0

    end

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


    --------------------------------------------------
    -- CURRENT POSITION
    --------------------------------------------------

    local position =
        state.navigation.position
        or
        {
            x = 0,
            y = 0,
            z = 0
        }


    local px =
        tonumber(position.x)
        or 0

    local py =
        tonumber(position.y)
        or 0

    local pz =
        tonumber(position.z)
        or 0


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    local tx =
        tonumber(target.x)
        or 0

    local ty =
        tonumber(target.y)
        or 0

    local tz =
        tonumber(target.z)
        or 0


    --------------------------------------------------
    -- DELTA
    --------------------------------------------------

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
-- POSITION INTEGRATION
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
        tonumber(velocity.x)
        or 0


    local vy =
        tonumber(velocity.y)
        or 0


    local vz =
        tonumber(velocity.z)
        or 0


    --------------------------------------------------
    -- X/Z INTEGRATION
    --------------------------------------------------

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

    if state.navigation.altitude
        ~= nil then

        state.navigation.position.y =
            state.navigation.altitude -
            state.navigation.startAltitude

    end

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
        or 0


    state.navigation.position = {
        x = 0,
        y = 0,
        z = 0
    }


    --------------------------------------------------
    -- If user manually defined a start position,
    -- preserve it.
    --------------------------------------------------

    if type(
        state.startPosition
    ) == "table"
    and
    state.startPosition.set == true then

        state.navigation.position.x =
            tonumber(
                state.startPosition.x
            )
            or 0


        state.navigation.position.y =
            tonumber(
                state.startPosition.y
            )
            or 0


        state.navigation.position.z =
            tonumber(
                state.startPosition.z
            )
            or 0

    end

end


--------------------------------------------------
-- RUN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- INITIAL STATE
    --------------------------------------------------

    state.navigation =
        state.navigation
        or {}


    state.navigation.online =
        false


    state.navigation.status =
        "STARTING"


    state.navigation.position = {
        x = 0,
        y = 0,
        z = 0
    }


    state.navigation.velocity = {
        x = 0,
        y = 0,
        z = 0
    }


    state.navigation.distance =
        0


    state.navigation.bearing =
        0


    state.navigation.heading =
        0


    state.navigation.elevation =
        0


    state.navigation.relativeAngle =
        0


    state.navigation.closureRate =
        0


    state.navigation.altitude =
        0


    state.navigation.verticalSpeed =
        0


    state.navigation.airPressure =
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


    state.navigation.accelerationX =
        0

    state.navigation.accelerationY =
        0

    state.navigation.accelerationZ =
        0


    state.navigation.navigationTable =
        false


    state.navigation.altitudeSensor =
        false


    state.navigation.gimbalSensor =
        false


    state.navigation.velocitySensor =
        false


    --------------------------------------------------
    -- INITIAL ALTITUDE
    --------------------------------------------------

    if altitudeSensor then

        local ok,
        altitude =
            safeCall(
                altitudeSensor,
                "getHeight"
            )


        if ok
            and
            numeric(altitude) then

            state.navigation.altitude =
                altitude

        end

    end


    --------------------------------------------------
    -- START POSITION
    --------------------------------------------------

    initializeStart(
        state
    )


    --------------------------------------------------
    -- TIME
    --------------------------------------------------

    local lastTime =
        os.clock()


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do


        --------------------------------------------------
        -- DT
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
                0.05

        end


        --------------------------------------------------
        -- SENSORS
        --------------------------------------------------

        updateNavigationTable(
            state
        )


        updateAltitude(
            state
        )


        updateVelocity(
            state
        )


        updateGimbal(
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
        -- SIGNAL STATUS
        --------------------------------------------------

        updateSignalState(
            state
        )


        --------------------------------------------------
        -- LAST UPDATE
        --------------------------------------------------

        state.navigation.lastUpdate =
            os.clock()


        --------------------------------------------------
        -- ERROR
        --------------------------------------------------

        state.navigation.error =
            nil


        --------------------------------------------------
        -- LOOP
        --------------------------------------------------

        sleep(
            0.05
        )

    end


    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

    state.navigation.online =
        false


    state.navigation.navigationTable =
        false


    state.navigation.altitudeSensor =
        false


    state.navigation.gimbalSensor =
        false


    state.navigation.velocitySensor =
        false


    state.navigation.status =
        "OFFLINE"

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}