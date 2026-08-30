-- Missile Navigation System
-- Create: Avionics / Create: Aeronautics
-- CC:Tweaked
--
-- Position model:
-- X/Y/Z are relative to the position where
-- the navigation system starts.
--
-- X/Z are reconstructed by integrating velocity.
-- Y is taken directly from Altitude Sensor.
--
-- Velocity sensors provide body-frame velocity.
-- Navigation Table orientation is used to convert
-- body-frame velocity into world-frame velocity.

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

local velocitySensors = {
    x = nil,
    y = nil,
    z = nil
}

for _, name in ipairs(peripheral.getNames()) do

    if peripheral.getType(name) ==
        "velocity_sensor" then

        local sensor =
            peripheral.wrap(name)

        if sensor then

            local ok, axis =
                pcall(sensor.getAxis)

            if ok then

                if axis == "x"
                    and not velocitySensors.x then

                    velocitySensors.x =
                        sensor

                elseif axis == "y"
                    and not velocitySensors.y then

                    velocitySensors.y =
                        sensor

                elseif axis == "z"
                    and not velocitySensors.z then

                    velocitySensors.z =
                        sensor
                end
            end
        end
    end
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
        return nil
    end

    local fn =
        object[method]

    if type(fn) ~= "function" then
        return nil
    end

    local ok, a, b, c, d =
        pcall(fn, ...)

    if ok then
        return a, b, c, d
    end

    return nil
end


--------------------------------------------------
-- QUATERNION ROTATION
--------------------------------------------------
--
-- Converts a body-frame vector into the
-- world-frame using the navigation table
-- orientation quaternion.
--
-- Quaternion:
-- x, y, z, w
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
-- MODULE
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- MAKE SURE STATE TABLES EXIST
    --------------------------------------------------

    if not state.navigation then
        state.navigation = {}
    end

    if not state.navigation.position then

        state.navigation.position = {
            x = 0,
            y = 0,
            z = 0
        }

    end

    if not state.navigation.velocity then

        state.navigation.velocity = {
            x = 0,
            y = 0,
            z = 0
        }

    end


    --------------------------------------------------
    -- INITIAL VALUES
    --------------------------------------------------

    state.navigation.online = false
    state.navigation.status = "STARTING"

    state.navigation.positionValid = false

    state.navigation.gps = false

    state.navigation.distance = 0
    state.navigation.closureRate = 0

    state.navigation.targetX = 0
    state.navigation.targetY = 0
    state.navigation.targetZ = 0

    state.navigation.hasNavTarget = false


    --------------------------------------------------
    -- START POSITION
    --------------------------------------------------

    local startAltitude = 0

    if altitudeSensor then

        local altitude =
            safeCall(
                altitudeSensor,
                "getHeight"
            )

        if type(altitude) == "number" then

            startAltitude =
                altitude

        end
    end


    state.navigation.startPosition = {
        x = 0,
        y = startAltitude,
        z = 0
    }


    state.navigation.position = {
        x = 0,
        y = 0,
        z = 0
    }


    state.navigation.startAltitude =
        startAltitude


    --------------------------------------------------
    -- TIMING
    --------------------------------------------------

    local lastTime =
        os.clock()

    local previousDistance = nil


    --------------------------------------------------
    -- SENSOR UPDATE
    --------------------------------------------------

    local function updateSensors()

        --------------------------------------------------
        -- ALTITUDE
        --------------------------------------------------

        if altitudeSensor then

            state.navigation.altitudeSensor =
                true

            local altitude =
                safeCall(
                    altitudeSensor,
                    "getHeight"
                )

            if type(altitude) == "number" then

                state.navigation.altitude =
                    altitude

                state.navigation.position.y =
                    altitude -
                    state.navigation.startAltitude

            end


            local verticalSpeed =
                safeCall(
                    altitudeSensor,
                    "getVerticalSpeed"
                )

            if type(verticalSpeed) == "number" then

                state.navigation.verticalSpeed =
                    verticalSpeed

            end


            local pressure =
                safeCall(
                    altitudeSensor,
                    "getAirPressure"
                )

            if type(pressure) == "number" then

                state.navigation.airPressure =
                    pressure

            end

        else

            state.navigation.altitudeSensor =
                false

        end


        --------------------------------------------------
        -- VELOCITY
        --------------------------------------------------

        local bodyVX = 0
        local bodyVY = 0
        local bodyVZ = 0

        local hasVelocity =
            false


        if velocitySensors.x then

            local value =
                safeCall(
                    velocitySensors.x,
                    "getVelocity"
                )

            if type(value) == "number" then

                bodyVX = value
                hasVelocity = true

            end
        end


        if velocitySensors.y then

            local value =
                safeCall(
                    velocitySensors.y,
                    "getVelocity"
                )

            if type(value) == "number" then

                bodyVY = value
                hasVelocity = true

            end
        end


        if velocitySensors.z then

            local value =
                safeCall(
                    velocitySensors.z,
                    "getVelocity"
                )

            if type(value) == "number" then

                bodyVZ = value
                hasVelocity = true

            end
        end


        state.navigation.velocitySensorX =
            velocitySensors.x ~= nil

        state.navigation.velocitySensorY =
            velocitySensors.y ~= nil

        state.navigation.velocitySensorZ =
            velocitySensors.z ~= nil


        --------------------------------------------------
        -- ORIENTATION
        --------------------------------------------------

        local qx = 0
        local qy = 0
        local qz = 0
        local qw = 1

        local orientationValid =
            false


        if navigationTable then

            local orientation =
                safeCall(
                    navigationTable,
                    "getOrientation"
                )

            if type(orientation) == "table" then

                qx =
                    tonumber(orientation[1])
                    or 0

                qy =
                    tonumber(orientation[2])
                    or 0

                qz =
                    tonumber(orientation[3])
                    or 0

                qw =
                    tonumber(orientation[4])
                    or 1

                orientationValid =
                    true

            end

        end


        --------------------------------------------------
        -- BODY -> WORLD VELOCITY
        --------------------------------------------------

        local worldVX =
            bodyVX

        local worldVY =
            bodyVY

        local worldVZ =
            bodyVZ


        if orientationValid then

            worldVX,
            worldVY,
            worldVZ =
                rotateVector(
                    bodyVX,
                    bodyVY,
                    bodyVZ,
                    qx,
                    qy,
                    qz,
                    qw
                )

        end


        --------------------------------------------------
        -- VELOCITY STATE
        --------------------------------------------------

        state.navigation.velocity.x =
            worldVX

        state.navigation.velocity.y =
            worldVY

        state.navigation.velocity.z =
            worldVZ


        state.navigation.speed =
            math.sqrt(
                worldVX * worldVX +
                worldVY * worldVY +
                worldVZ * worldVZ
            )


        --------------------------------------------------
        -- POSITION INTEGRATION
        --------------------------------------------------

        local now =
            os.clock()

        local dt =
            now - lastTime

        lastTime =
            now


        -- Prevent huge jumps after lag
        if dt > 0 and dt < 0.5 then

            state.navigation.position.x =
                state.navigation.position.x +
                worldVX * dt

            state.navigation.position.z =
                state.navigation.position.z +
                worldVZ * dt

        end


        --------------------------------------------------
        -- VALID POSITION
        --------------------------------------------------

        state.navigation.positionValid =
            hasVelocity
            or altitudeSensor ~= nil

    end


    --------------------------------------------------
    -- MANUAL TARGET
    --------------------------------------------------

    local function updateTarget()

        local target =
            state.target


        if type(target) ~= "table"
            or target.set ~= true then

            state.navigation.hasNavTarget =
                false

            return

        end


        local tx =
            tonumber(target.x)

        local ty =
            tonumber(target.y)

        local tz =
            tonumber(target.z)


        if not tx
            or not ty
            or not tz then

            state.navigation.hasNavTarget =
                false

            return

        end


        state.navigation.targetX =
            tx

        state.navigation.targetY =
            ty

        state.navigation.targetZ =
            tz


        state.navigation.hasNavTarget =
            true

    end


    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local function updateDistance()

        if not state.navigation.hasNavTarget then

            state.navigation.distance =
                0

            state.navigation.closureRate =
                0

            previousDistance =
                nil

            return

        end


        local px =
            state.navigation.position.x

        local py =
            state.navigation.position.y

        local pz =
            state.navigation.position.z


        local tx =
            state.navigation.targetX

        local ty =
            state.navigation.targetY

        local tz =
            state.navigation.targetZ


        local dx =
            tx - px

        local dy =
            ty - py

        local dz =
            tz - pz


        local distance =
            math.sqrt(
                dx * dx +
                dy * dy +
                dz * dz
            )


        state.navigation.distance =
            distance


        --------------------------------------------------
        -- CLOSURE RATE
        --------------------------------------------------

        local now =
            os.clock()


        if previousDistance then

            local dt =
                now - previousDistance.time

            if dt > 0 then

                state.navigation.closureRate =
                    (
                        previousDistance.distance -
                        distance
                    ) / dt

            end
        end


        previousDistance = {
            distance = distance,
            time = now
        }


        --------------------------------------------------
        -- TARGET VECTOR
        --------------------------------------------------

        state.navigation.targetDeltaX =
            dx

        state.navigation.targetDeltaY =
            dy

        state.navigation.targetDeltaZ =
            dz


        --------------------------------------------------
        -- ELEVATION
        --------------------------------------------------

        state.navigation.elevation =
            dy


        --------------------------------------------------
        -- SIMPLE WORLD BEARING
        --------------------------------------------------

        local horizontalDistance =
            math.sqrt(
                dx * dx +
                dz * dz
            )


        if horizontalDistance >
            0.001 then

            state.navigation.bearing =
                math.atan(
                    dx,
                    dz
                )

        else

            state.navigation.bearing =
                0

        end

    end


    --------------------------------------------------
    -- NAVIGATION TABLE
    --------------------------------------------------

    local function updateNavigationTable()

        if not navigationTable then

            state.navigation.navigationTable =
                false

            return

        end


        state.navigation.navigationTable =
            true


        --------------------------------------------------
        -- REAL NAV TABLE TARGET
        --------------------------------------------------

        local hasTarget =
            safeCall(
                navigationTable,
                "hasTarget"
            )


        if hasTarget then

            local bearing =
                safeCall(
                    navigationTable,
                    "getBearingRad"
                )

            if type(bearing) == "number" then

                state.navigation.navTableBearing =
                    bearing

            end


            local closure =
                safeCall(
                    navigationTable,
                    "getClosureRate"
                )

            if type(closure) == "number" then

                state.navigation.navTableClosureRate =
                    closure

            end

        end


        --------------------------------------------------
        -- HEADING
        --------------------------------------------------

        local heading =
            safeCall(
                navigationTable,
                "getHeadingRad"
            )


        if type(heading) == "number" then

            state.navigation.heading =
                heading

        end

    end


    --------------------------------------------------
    -- GIMBAL
    --------------------------------------------------

    local function updateGimbal()

        if not gimbalSensor then

            state.navigation.gimbalSensor =
                false

            return

        end


        state.navigation.gimbalSensor =
            true


        local angles =
            safeCall(
                gimbalSensor,
                "getAnglesRad"
            )


        if type(angles) == "table" then

            state.navigation.pitch =
                tonumber(angles[1])
                or 0

            state.navigation.roll =
                tonumber(angles[2])
                or 0

        end


        local rates =
            safeCall(
                gimbalSensor,
                "getAngularRatesRad"
            )


        if type(rates) == "table" then

            state.navigation.angularRateX =
                tonumber(rates[1])
                or 0

            state.navigation.angularRateY =
                tonumber(rates[2])
                or 0

            state.navigation.angularRateZ =
                tonumber(rates[3])
                or 0

        end


        local gravity =
            safeCall(
                gimbalSensor,
                "getGravity"
            )


        if type(gravity) == "table" then

            state.navigation.gravityX =
                tonumber(gravity[1])
                or 0

            state.navigation.gravityY =
                tonumber(gravity[2])
                or 0

            state.navigation.gravityZ =
                tonumber(gravity[3])
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


        local acceleration =
            safeCall(
                gimbalSensor,
                "getLinearAcceleration"
            )


        if type(acceleration) == "table" then

            state.navigation.accelerationX =
                tonumber(acceleration[1])
                or 0

            state.navigation.accelerationY =
                tonumber(acceleration[2])
                or 0

            state.navigation.accelerationZ =
                tonumber(acceleration[3])
                or 0

        end

    end


    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    local function updateStatus()

        local online =
            navigationTable ~= nil
            or altitudeSensor ~= nil
            or gimbalSensor ~= nil
            or velocitySensors.x ~= nil
            or velocitySensors.y ~= nil
            or velocitySensors.z ~= nil


        state.navigation.online =
            online


        if online then

            state.navigation.status =
                "ONLINE"

        else

            state.navigation.status =
                "OFFLINE"

        end


        state.navigation.lastUpdate =
            os.clock()

    end


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system.running do

        state.navigation.error =
            nil


        updateStatus()

        updateSensors()

        updateTarget()

        updateDistance()

        updateNavigationTable()

        updateGimbal()


        sleep(0.05)

    end


    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

    state.navigation.online =
        false

    state.navigation.status =
        "OFFLINE"

end


--------------------------------------------------
-- MODULE
--------------------------------------------------

return {
    run = run
}