-- Navigation module
-- Reads data from the Navigation Table.

local state = require("state")

--------------------------------------------------
-- FIND NAVIGATION TABLE
--------------------------------------------------

local navigation =
    peripheral.find("navigation_table")

if not navigation then

    state.navigation.online = false

    while true do
        sleep(1)
    end

end

state.navigation.online = true

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

    if ok then
        return result
    end

    return nil
end

--------------------------------------------------
-- TRY METHODS
--------------------------------------------------

local function tryMethods(methods)

    for _, method in ipairs(methods) do

        local value =
            safeCall(method)

        if value ~= nil then
            return value
        end

    end

    return nil
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    --------------------------------------------------
    -- HEADING
    --------------------------------------------------

    local heading =
        tryMethods({
            "getHeading",
            "getHeadingRad",
            "getYaw"
        })

    if heading then
        state.navigation.heading = heading
    end

    --------------------------------------------------
    -- BEARING
    --------------------------------------------------

    local bearing =
        tryMethods({
            "getBearing",
            "getBearingRad",
            "getTargetBearing"
        })

    if bearing then
        state.navigation.bearing = bearing
    end

    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local distance =
        tryMethods({
            "getDistance",
            "getDistanceToTarget",
            "getTargetDistance"
        })

    if distance then
        state.navigation.distance = distance
    end

    --------------------------------------------------
    -- VELOCITY
    --------------------------------------------------

    local velocity =
        tryMethods({
            "getVelocity",
            "getVelocityVector",
            "getLinearVelocity"
        })

    if type(velocity) == "table" then

        state.navigation.velocity.x =
            velocity.x or velocity[1] or 0

        state.navigation.velocity.y =
            velocity.y or velocity[2] or 0

        state.navigation.velocity.z =
            velocity.z or velocity[3] or 0

    end

    --------------------------------------------------
    -- ACCELERATION
    --------------------------------------------------

    local acceleration =
        tryMethods({
            "getAcceleration",
            "getAccelerationVector"
        })

    if type(acceleration) == "table" then

        state.navigation.acceleration.x =
            acceleration.x or acceleration[1] or 0

        state.navigation.acceleration.y =
            acceleration.y or acceleration[2] or 0

        state.navigation.acceleration.z =
            acceleration.z or acceleration[3] or 0

    end

    --------------------------------------------------
    -- GRAVITY
    --------------------------------------------------

    local gravity =
        tryMethods({
            "getGravity",
            "getGravityVector"
        })

    if type(gravity) == "number" then

        state.navigation.gravity =
            gravity

    elseif type(gravity) == "table" then

        local gx =
            gravity.x or gravity[1] or 0

        local gy =
            gravity.y or gravity[2] or 0

        local gz =
            gravity.z or gravity[3] or 0

        state.navigation.gravity =
            math.sqrt(
                gx * gx +
                gy * gy +
                gz * gz
            )

    end
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    update()

    sleep(0.05)

end