-- Navigation and flight sensor module

local state = require("state")

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
-- GPS
--------------------------------------------------

local function updateGPS()

    local x, y, z =
        gps.locate(1, false)

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

--------------------------------------------------
-- NAVIGATION TABLE
--------------------------------------------------

local function updateNavigationTable()

    if not navigationTable then
        state.navigation.navigationTable = false
        return
    end

    state.navigation.navigationTable = true

    local ok, value

    ok, value =
        pcall(
            navigationTable.hasTarget
        )

    if ok and value ~= nil then
        state.navigation.hasNavTarget = value
    end

    ok, value =
        pcall(
            navigationTable.getBearingRad
        )

    if ok and value ~= nil then
        state.navigation.bearing = value
    end

    ok, value =
        pcall(
            navigationTable.getRelativeAngleRad
        )

    if ok and value ~= nil then
        state.navigation.relativeAngle = value
    end

    ok, value =
        pcall(
            navigationTable.getVerticalOffsetToTarget
        )

    if ok and value ~= nil then
        state.navigation.elevation = value
    end

    ok, value =
        pcall(
            navigationTable.getDistanceToTarget
        )

    if ok and value ~= nil then
        state.navigation.distance = value
    end

    ok, value =
        pcall(
            navigationTable.getClosureRate
        )

    if ok and value ~= nil then
        state.navigation.closureRate = value
    end

    ok, value =
        pcall(
            navigationTable.getHeadingRad
        )

    if ok and value ~= nil then
        state.navigation.heading = value
    end
end

--------------------------------------------------
-- ALTITUDE SENSOR
--------------------------------------------------

local function updateAltitude()

    if not altitudeSensor then

        state.navigation.altitudeSensor = false

        return
    end

    state.navigation.altitudeSensor = true

    local ok, value

    ok, value =
        pcall(
            altitudeSensor.getHeight
        )

    if ok and value ~= nil then
        state.navigation.altitude = value
    end

    ok, value =
        pcall(
            altitudeSensor.getVerticalSpeed
        )

    if ok and value ~= nil then
        state.navigation.verticalSpeed = value
    end

    ok, value =
        pcall(
            altitudeSensor.getAirPressure
        )

    if ok and value ~= nil then
        state.navigation.airPressure = value
    end
end

--------------------------------------------------
-- GIMBAL SENSOR
--------------------------------------------------

local function updateGimbal()

    if not gimbalSensor then

        state.navigation.gimbalSensor = false

        return
    end

    state.navigation.gimbalSensor = true

    --------------------------------------------------
    -- ATTITUDE
    --------------------------------------------------

    local ok, angles =
        pcall(
            gimbalSensor.getAnglesRad
        )

    if ok and type(angles) == "table" then

        state.navigation.pitch =
            angles[1] or 0

        state.navigation.roll =
            angles[2] or 0

    end

    --------------------------------------------------
    -- ANGULAR RATES
    --------------------------------------------------

    ok, angles =
        pcall(
            gimbalSensor.getAngularRatesRad
        )

    if ok and type(angles) == "table" then

        state.navigation.angularRateX =
            angles[1] or 0

        state.navigation.angularRateY =
            angles[2] or 0

        state.navigation.angularRateZ =
            angles[3] or 0

    end

    --------------------------------------------------
    -- GRAVITY
    --------------------------------------------------

    ok, angles =
        pcall(
            gimbalSensor.getGravity
        )

    if ok and type(angles) == "table" then

        state.navigation.gravityX =
            angles[1] or 0

        state.navigation.gravityY =
            angles[2] or 0

        state.navigation.gravityZ =
            angles[3] or 0

    end

    --------------------------------------------------
    -- LINEAR ACCELERATION
    --------------------------------------------------

    ok, angles =
        pcall(
            gimbalSensor.getLinearAcceleration
        )

    if ok and type(angles) == "table" then

        state.navigation.accelerationX =
            angles[1] or 0

        state.navigation.accelerationY =
            angles[2] or 0

        state.navigation.accelerationZ =
            angles[3] or 0

    end
end

--------------------------------------------------
-- STATUS
--------------------------------------------------

local function updateStatus()

    state.navigation.online =
        navigationTable ~= nil
        or altitudeSensor ~= nil
        or gimbalSensor ~= nil

end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    updateStatus()

    updateGPS()
    updateNavigationTable()
    updateAltitude()
    updateGimbal()

    sleep(0.05)
end

state.navigation.online = false
state.navigation.navigationTable = false
state.navigation.altitudeSensor = false
state.navigation.gimbalSensor = false
state.navigation.gps = false