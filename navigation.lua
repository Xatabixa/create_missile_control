-- Navigation and flight sensor module
-- Single-folder ComputerCraft compatible version

local navigationTable = peripheral.find("navigation_table")
local altitudeSensor = peripheral.find("altitude_sensor")
local gimbalSensor = peripheral.find("gimbal_sensor")

local velocitySensors = {
    x = nil,
    y = nil,
    z = nil
}

for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "velocity_sensor" then
        local sensor = peripheral.wrap(name)

        if sensor then
            local ok, axis = pcall(sensor.getAxis)

            if ok then
                if axis == "x" and not velocitySensors.x then
                    velocitySensors.x = sensor
                elseif axis == "y" and not velocitySensors.y then
                    velocitySensors.y = sensor
                elseif axis == "z" and not velocitySensors.z then
                    velocitySensors.z = sensor
                end
            end
        end
    end
end

local modem = peripheral.find("modem")
local gpsEnabled = modem ~= nil
local gpsTick = 0

local function safeCall(object, method, ...)
    if not object then
        return nil
    end

    local fn = object[method]

    if type(fn) ~= "function" then
        return nil
    end

    local ok, a, b, c = pcall(fn, ...)

    if ok then
        return a, b, c
    end

    return nil
end

local function updateGPS(state)
    if not gpsEnabled then
        state.navigation.gps = false
        state.navigation.positionValid = false
        return
    end

    local now = os.clock()

    if now < gpsTick then
        return
    end

    gpsTick = now + 0.5

    local x, y, z = gps.locate(0.5, false)

    if x ~= nil then
        state.navigation.position.x = x
        state.navigation.position.y = y
        state.navigation.position.z = z

        state.navigation.positionValid = true
        state.navigation.gps = true
    else
        state.navigation.positionValid = false
        state.navigation.gps = false
    end
end

local function updateNavigationTable(state)
    if not navigationTable then
        state.navigation.navigationTable = false
        state.navigation.hasNavTarget = false
        return
    end

    state.navigation.navigationTable = true

    local hasTarget = safeCall(navigationTable, "hasTarget")

    if hasTarget ~= nil then
        state.navigation.hasNavTarget = hasTarget
    end

    local bearing = safeCall(navigationTable, "getBearingRad")

    if bearing ~= nil then
        state.navigation.bearing = bearing
    end

    local relativeAngle =
        safeCall(navigationTable, "getRelativeAngleRad")

    if relativeAngle ~= nil then
        state.navigation.relativeAngle = relativeAngle
    end

    local elevation =
        safeCall(navigationTable, "getVerticalOffsetToTarget")

    if elevation ~= nil then
        state.navigation.elevation = elevation
    end

    local distance =
        safeCall(navigationTable, "getDistanceToTarget")

    if distance ~= nil then
        state.navigation.distance = distance
    end

    local closureRate =
        safeCall(navigationTable, "getClosureRate")

    if closureRate ~= nil then
        state.navigation.closureRate = closureRate
    end

    local heading =
        safeCall(navigationTable, "getHeadingRad")

    if heading ~= nil then
        state.navigation.heading = heading
    end
end

local function updateAltitude(state)
    if not altitudeSensor then
        state.navigation.altitudeSensor = false
        return
    end

    state.navigation.altitudeSensor = true

    local height =
        safeCall(altitudeSensor, "getHeight")

    if height ~= nil then
        state.navigation.altitude = height
    end

    local verticalSpeed =
        safeCall(altitudeSensor, "getVerticalSpeed")

    if verticalSpeed ~= nil then
        state.navigation.verticalSpeed = verticalSpeed
    end

    local pressure =
        safeCall(altitudeSensor, "getAirPressure")

    if pressure ~= nil then
        state.navigation.airPressure = pressure
    end
end

local function updateVelocity(state)
    local vx = safeCall(
        velocitySensors.x,
        "getVelocity"
    )

    local vy = safeCall(
        velocitySensors.y,
        "getVelocity"
    )

    local vz = safeCall(
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
        state.navigation.velocity.x = vx
    end

    if vy ~= nil then
        state.navigation.velocity.y = vy
    end

    if vz ~= nil then
        state.navigation.velocity.z = vz
    end

    local x = state.navigation.velocity.x or 0
    local y = state.navigation.velocity.y or 0
    local z = state.navigation.velocity.z or 0

    state.navigation.speed =
        math.sqrt(x * x + y * y + z * z)
end

local function updateGimbal(state)
    if not gimbalSensor then
        state.navigation.gimbalSensor = false
        return
    end

    state.navigation.gimbalSensor = true

    local angles =
        safeCall(gimbalSensor, "getAnglesRad")

    if type(angles) == "table" then
        state.navigation.pitch = angles[1] or 0
        state.navigation.roll = angles[2] or 0
    end

    local rates =
        safeCall(gimbalSensor, "getAngularRatesRad")

    if type(rates) == "table" then
        state.navigation.angularRateX = rates[1] or 0
        state.navigation.angularRateY = rates[2] or 0
        state.navigation.angularRateZ = rates[3] or 0
    end

    local gravity =
        safeCall(gimbalSensor, "getGravity")

    if type(gravity) == "table" then
        state.navigation.gravityX = gravity[1] or 0
        state.navigation.gravityY = gravity[2] or 0
        state.navigation.gravityZ = gravity[3] or 0

        local gx = state.navigation.gravityX
        local gy = state.navigation.gravityY
        local gz = state.navigation.gravityZ

        state.navigation.gravityMagnitude =
            math.sqrt(gx * gx + gy * gy + gz * gz)
    end

    local acceleration =
        safeCall(gimbalSensor, "getLinearAcceleration")

    if type(acceleration) == "table" then
        state.navigation.accelerationX = acceleration[1] or 0
        state.navigation.accelerationY = acceleration[2] or 0
        state.navigation.accelerationZ = acceleration[3] or 0
    end
end

local function updateStatus(state)
    local online =
        navigationTable ~= nil
        or altitudeSensor ~= nil
        or gimbalSensor ~= nil
        or velocitySensors.x ~= nil
        or velocitySensors.y ~= nil
        or velocitySensors.z ~= nil
        or gpsEnabled

    state.navigation.online = online

    if online then
        state.navigation.status = "ONLINE"
    else
        state.navigation.status = "OFFLINE"
    end

    state.navigation.lastUpdate = os.clock()
end

local function run(sharedState)
    local state = sharedState

    while state.system.running do
        state.navigation.error = nil

        updateStatus()
        updateGPS()
        updateNavigationTable()
        updateAltitude()
        updateVelocity()
        updateGimbal()

        sleep(0.05)
    end

    state.navigation.online = false
    state.navigation.status = "OFFLINE"
end

return {
    run = run
}