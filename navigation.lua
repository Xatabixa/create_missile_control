-- Navigation and flight sensor module
-- Create: Aeronautics / Create: Avionics
-- CC:Tweaked
-- Single-folder ComputerCraft compatible version

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

                    velocitySensors.x = sensor

                elseif axis == "y"
                    and not velocitySensors.y then

                    velocitySensors.y = sensor

                elseif axis == "z"
                    and not velocitySensors.z then

                    velocitySensors.z = sensor
                end
            end
        end
    end
end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- SAFE PERIPHERAL CALL
    --------------------------------------------------

    local function safeCall(
        object,
        method,
        ...
    )

        if not object then
            return nil
        end

        local fn = object[method]

        if type(fn) ~= "function" then
            return nil
        end

        local ok, a, b, c, d =
            pcall(fn, ...)

        if ok then
            return a, b, c, d
        end

        state.navigation.error =
            tostring(b or a)

        return nil
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


        -- Target available

        local hasTarget =
            safeCall(
                navigationTable,
                "hasTarget"
            )

        if hasTarget ~= nil then

            state.navigation.hasNavTarget =
                hasTarget
        end


        -- Bearing

        local bearing =
            safeCall(
                navigationTable,
                "getBearingRad"
            )

        if bearing ~= nil then

            state.navigation.bearing =
                bearing
        end


        -- Relative angle

        local relativeAngle =
            safeCall(
                navigationTable,
                "getRelativeAngleRad"
            )

        if relativeAngle ~= nil then

            state.navigation.relativeAngle =
                relativeAngle
        end


        -- Vertical offset

        local elevation =
            safeCall(
                navigationTable,
                "getVerticalOffsetToTarget"
            )

        if elevation ~= nil then

            state.navigation.elevation =
                elevation
        end


        -- Distance

        local distance =
            safeCall(
                navigationTable,
                "getDistanceToTarget"
            )

        if distance ~= nil then

            state.navigation.distance =
                distance
        end


        -- Closure rate

        local closureRate =
            safeCall(
                navigationTable,
                "getClosureRate"
            )

        if closureRate ~= nil then

            state.navigation.closureRate =
                closureRate
        end


        -- Heading

        local heading =
            safeCall(
                navigationTable,
                "getHeadingRad"
            )

        if heading ~= nil then

            state.navigation.heading =
                heading
        end
    end


    --------------------------------------------------
    -- MANUAL TARGET
    --------------------------------------------------

    local function updateLocalTarget()

        local target =
            state.target

        if type(target) ~= "table"
            or target.set ~= true then

            return
        end


        state.navigation.hasNavTarget =
            true


        state.navigation.targetX =
            tonumber(target.x) or 0

        state.navigation.targetY =
            tonumber(target.y) or 0

        state.navigation.targetZ =
            tonumber(target.z) or 0
    end


    --------------------------------------------------
    -- ALTITUDE SENSOR
    --------------------------------------------------

    local function updateAltitude()

        if not altitudeSensor then

            state.navigation.altitudeSensor =
                false

            return
        end

        state.navigation.altitudeSensor =
            true


        -- Height

        local height =
            safeCall(
                altitudeSensor,
                "getHeight"
            )

        if height ~= nil then

            state.navigation.altitude =
                height
        end


        -- Vertical speed

        local verticalSpeed =
            safeCall(
                altitudeSensor,
                "getVerticalSpeed"
            )

        if verticalSpeed ~= nil then

            state.navigation.verticalSpeed =
                verticalSpeed
        end


        -- Air pressure

        local pressure =
            safeCall(
                altitudeSensor,
                "getAirPressure"
            )

        if pressure ~= nil then

            state.navigation.airPressure =
                pressure
        end
    end


    --------------------------------------------------
    -- VELOCITY SENSORS
    --------------------------------------------------

    local function updateVelocity()

        local vx =
            safeCall(
                velocitySensors.x,
                "getVelocity"
            )

        local vy =
            safeCall(
                velocitySensors.y,
                "getVelocity"
            )

        local vz =
            safeCall(
                velocitySensors.z,
                "getVelocity"
            )


        state.navigation.velocitySensorX =
            velocitySensors.x ~= nil

        state.navigation.velocitySensorY =
            velocitySensors.y ~= nil

        state.navigation.velocitySensorZ =
            velocitySensors.z ~= nil


        if vx ~= nil then

            state.navigation.velocity.x =
                vx
        end


        if vy ~= nil then

            state.navigation.velocity.y =
                vy
        end


        if vz ~= nil then

            state.navigation.velocity.z =
                vz
        end


        local x =
            state.navigation.velocity.x or 0

        local y =
            state.navigation.velocity.y or 0

        local z =
            state.navigation.velocity.z or 0


        state.navigation.speed =
            math.sqrt(
                x * x +
                y * y +
                z * z
            )
    end


    --------------------------------------------------
    -- GIMBAL SENSOR
    --------------------------------------------------

    local function updateGimbal()

        if not gimbalSensor then

            state.navigation.gimbalSensor =
                false

            return
        end

        state.navigation.gimbalSensor =
            true


        -- Angles

        local angles =
            safeCall(
                gimbalSensor,
                "getAnglesRad"
            )

        if type(angles) == "table" then

            state.navigation.pitch =
                angles[1] or 0

            state.navigation.roll =
                angles[2] or 0
        end


        -- Angular rates

        local rates =
            safeCall(
                gimbalSensor,
                "getAngularRatesRad"
            )

        if type(rates) == "table" then

            state.navigation.angularRateX =
                rates[1] or 0

            state.navigation.angularRateY =
                rates[2] or 0

            state.navigation.angularRateZ =
                rates[3] or 0
        end


        -- Gravity vector

        local gravity =
            safeCall(
                gimbalSensor,
                "getGravity"
            )

        if type(gravity) == "table" then

            state.navigation.gravityX =
                gravity[1] or 0

            state.navigation.gravityY =
                gravity[2] or 0

            state.navigation.gravityZ =
                gravity[3] or 0


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


        -- Linear acceleration

        local acceleration =
            safeCall(
                gimbalSensor,
                "getLinearAcceleration"
            )

        if type(acceleration) == "table" then

            state.navigation.accelerationX =
                acceleration[1] or 0

            state.navigation.accelerationY =
                acceleration[2] or 0

            state.navigation.accelerationZ =
                acceleration[3] or 0
        end
    end


    --------------------------------------------------
    -- SYSTEM STATUS
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

        updateNavigationTable()

        updateLocalTarget()

        updateAltitude()

        updateVelocity()

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