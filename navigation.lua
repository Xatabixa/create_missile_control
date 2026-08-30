-- Navigation module
-- Reads telemetry from the Navigation Table.

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
state.navigation.status = "ONLINE"

--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function safeCall(method)

    if not navigation[method] then
        return nil
    end

    local ok, result =
        pcall(
            navigation[method]
        )

    if not ok then
        return nil
    end

    return result
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    --------------------------------------------------
    -- TARGET STATUS
    --------------------------------------------------

    local hasTarget =
        safeCall("hasTarget")

    if hasTarget ~= nil then

        state.navigation.hasTarget =
            hasTarget

    end

    --------------------------------------------------
    -- BEARING
    --------------------------------------------------

    local bearing =
        safeCall("getBearingRad")

    if bearing == nil then

        bearing =
            safeCall("getBearing")

    end

    if bearing ~= nil then

        state.navigation.bearing =
            bearing

    end

    --------------------------------------------------
    -- VERTICAL OFFSET
    --------------------------------------------------

    local elevation =
        safeCall(
            "getVerticalOffsetToTarget"
        )

    if elevation ~= nil then

        state.navigation.elevation =
            elevation

    end

    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local distance =
        safeCall(
            "getDistanceToTarget"
        )

    if distance ~= nil then

        state.navigation.distance =
            distance

    end

    --------------------------------------------------
    -- CLOSURE RATE
    --------------------------------------------------

    local closure =
        safeCall("getClosureRate")

    if closure ~= nil then

        state.navigation.closureRate =
            closure

    end

    --------------------------------------------------
    -- HEADING
    --------------------------------------------------

    local heading =
        safeCall("getHeadingRad")

    if heading == nil then

        heading =
            safeCall("getHeading")

    end

    if heading ~= nil then

        state.navigation.heading =
            heading

    end

    --------------------------------------------------
    -- RELATIVE ANGLE
    --------------------------------------------------

    local relativeAngle =
        safeCall(
            "getRelativeAngleRad"
        )

    if relativeAngle == nil then

        relativeAngle =
            safeCall(
                "getRelativeAngle"
            )

    end

    if relativeAngle ~= nil then

        state.navigation.relativeAngle =
            relativeAngle

    end

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    state.navigation.online = true
    state.navigation.status = "ONLINE"

    state.navigation.updateCount =
        state.navigation.updateCount + 1

    state.navigation.lastUpdate =
        os.clock()

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
