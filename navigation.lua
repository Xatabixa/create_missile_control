-- Navigation telemetry module

local state = require("state")

--------------------------------------------------
-- FIND NAVIGATION TABLE
--------------------------------------------------

local navigation =
    peripheral.find("navigation_table")

if not navigation then

    state.navigation.online = false
    state.navigation.status = "OFFLINE"

    while state.system.running do
        sleep(1)
    end

    return
end

state.navigation.online = true
state.navigation.status = "WAITING"

--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function call(method)

    if not navigation[method] then
        return nil
    end

    local ok, result =
        pcall(navigation[method])

    if not ok then
        return nil
    end

    return result
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    local dataReceived = false

    --------------------------------------------------
    -- BEARING
    --------------------------------------------------

    local bearing =
        call("getBearingRad")

    if bearing == nil then
        bearing =
            call("getBearing")
    end

    if bearing ~= nil then

        state.navigation.bearing =
            bearing

        dataReceived = true
    end

    --------------------------------------------------
    -- HEADING
    --------------------------------------------------

    local heading =
        call("getHeadingRad")

    if heading == nil then
        heading =
            call("getHeading")
    end

    if heading ~= nil then

        state.navigation.heading =
            heading

        dataReceived = true
    end

    --------------------------------------------------
    -- RELATIVE ANGLE
    --------------------------------------------------

    local relative =
        call("getRelativeAngleRad")

    if relative == nil then
        relative =
            call("getRelativeAngle")
    end

    if relative ~= nil then

        state.navigation.relativeAngle =
            relative

        dataReceived = true
    end

    --------------------------------------------------
    -- VERTICAL OFFSET
    --------------------------------------------------

    local vertical =
        call("getVerticalOffsetToTarget")

    if vertical ~= nil then

        state.navigation.verticalOffset =
            vertical

        dataReceived = true
    end

    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local distance =
        call("getDistanceToTarget")

    if distance ~= nil then

        state.navigation.distance =
            distance

        dataReceived = true
    end

    --------------------------------------------------
    -- CLOSURE RATE
    --------------------------------------------------

    local closure =
        call("getClosureRate")

    if closure ~= nil then

        state.navigation.closureRate =
            closure

        dataReceived = true
    end

    --------------------------------------------------
    -- ORIENTATION
    --------------------------------------------------

    local orientation =
        call("getOrientation")

    if orientation ~= nil then

        state.navigation.orientation =
            orientation

        dataReceived = true
    end

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    state.navigation.online = true

    if dataReceived then
        state.navigation.status = "ONLINE"
    else
        state.navigation.status = "WAITING"
    end

    state.navigation.lastUpdate =
        os.clock()

    state.navigation.updateCount =
        state.navigation.updateCount + 1
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    update()

    sleep(0.05)
end

state.navigation.online = false
state.navigation.status = "OFFLINE"
