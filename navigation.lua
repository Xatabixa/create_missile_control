-- Navigation and flight sensor module

local state = require("state")

local navigationTable = peripheral.find("navigation_table")
local altitudeSensor = peripheral.find("altitude_sensor")
local gimbalSensor = peripheral.find("gimbal_sensor")
local velocitySensor = peripheral.find("velocity_sensor")

local function updateGPS()
    local x, y, z = gps.locate(1, false)

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

local function updateNavigationTable()
    if not navigationTable then
        state.navigation.navigationTable = false
        return
    end

    state.navigation.navigationTable = true

    local ok, value

    ok, value = pcall(navigationTable.hasTarget)
    if ok and value ~= nil then state.navigation.hasNavTarget = value end

    ok, value = pcall(navigationTable.getBearingRad)
    if ok and value ~= nil then state.navigation.bearing = value end

    ok, value = pcall(navigationTable.getRelativeAngleRad)
    if ok and value ~= nil then state.navigation.relativeAngle = value end

    ok, value = pcall(navigationTable.getVerticalOffsetToTarget)
    if ok and value ~= nil then state.navigation.elevation = value end

    ok, value = pcall(navigationTable.getDistanceToTarget)
    if ok and value ~= nil then state.navigation.distance = value end

    ok, value = pcall(navigationTable.getClosureRate)
    if ok and value ~= nil then state.navigation.closureRate = value end

    ok, value = pcall(navigationTable.getHeadingRad)
    if ok and value ~= nil then state.navigation.heading = value end
end

local function updateAltitude()
    if not altitudeSensor then
        state.navigation.altitudeSensor = false
        return
    end

    state.navigation.altitudeSensor = true

    local ok, value = pcall(altitudeSensor.getHeight)
    if ok and value ~= nil then state.navigation.altitude = value end

    ok, value = pcall(altitudeSensor.getVerticalSpeed)
    if ok and value ~= nil then state.navigation.verticalSpeed = value end

    ok, value = pcall(altitudeSensor.getAirPressure)
    if ok and value ~= nil then state.navigation.airPressure = value end
end

local function updateVelocity()
    if not velocitySensor then return end

    local ok, values = pcall(velocitySensor.getVelocity)
    if ok and type(values) == "table" then
        state.navigation.velocity.x = values[1] or 0
        state.navigation.velocity.y = values[2] or 0
        state.navigation.velocity.z = values[3] or 0
    end
end

local function updateGimbal()
    if not gimbalSensor then
        state.navigation.gimbalSensor = false
        return
    end

    state.navigation.gimbalSensor = true

    local ok, values = pcall(gimbalSensor.getAnglesRad)
    if ok and type(values) == "table" then
        state.navigation.pitch = values[1] or 0
        state.navigation.roll = values[2] or 0
    end

    ok, values = pcall(gimbalSensor.getAngularRatesRad)
    if ok and type(values) == "table" then
        state.navigation.angularRateX = values[1] or 0
        state.navigation.angularRateY = values[2] or 0
        state.navigation.angularRateZ = values[3] or 0
    end

    ok, values = pcall(gimbalSensor.getGravity)
    if ok and type(values) == "table" then
        state.navigation.gravityX = values[1] or 0
        state.navigation.gravityY = values[2] or 0
        state.navigation.gravityZ = values[3] or 0
    end

    ok, values = pcall(gimbalSensor.getLinearAcceleration)
    if ok and type(values) == "table" then
        state.navigation.accelerationX = values[1] or 0
        state.navigation.accelerationY = values[2] or 0
        state.navigation.accelerationZ = values[3] or 0
    end
end

local function updateStatus()
    state.navigation.online =
        navigationTable ~= nil
        or altitudeSensor ~= nil
        or gimbalSensor ~= nil
        or velocitySensor ~= nil

    if not state.navigation.online then
        state.navigation.status = "OFFLINE"
    else
        state.navigation.status = "ONLINE"
    end
end

local function run()
    while state.system.running do
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

return { run = run }
