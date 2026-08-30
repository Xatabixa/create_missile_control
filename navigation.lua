-- Navigation subsystem
--
-- Position:
--   CC:Tweaked GPS
--
-- Orientation:
--   Create: Avionics navigation_table / gimbal_sensor
--
-- Target:
--   target.cfg

local state = ...

local GPS_INTERVAL = 0.75
local TARGET_INTERVAL = 0.20

local navigationTable = nil
local gimbalSensor = nil
local modem = nil

local lastX = nil
local lastY = nil
local lastZ = nil
local lastTime = nil

local gpsTimer
local targetTimer

--------------------------------------------------
-- SAFE METHOD CALL
--------------------------------------------------

local function safeCall(object, method, ...)

    if not object then
        return nil
    end

    if type(object[method]) ~= "function" then
        return nil
    end

    local args = {...}

    local ok, a, b, c, d =
        pcall(
            function()

                return object[method](
                    table.unpack(args)
                )

            end
        )

    if not ok then
        return nil
    end

    return a, b, c, d
end

--------------------------------------------------
-- FIND PERIPHERALS
--------------------------------------------------

local function findPeripherals()

    navigationTable =
        peripheral.find(
            "navigation_table"
        )

    gimbalSensor =
        peripheral.find(
            "gimbal_sensor"
        )

    modem =
        peripheral.find(
            "modem"
        )

    state.navigation.navTable =
        navigationTable ~= nil

    state.navigation.gimbal =
        gimbalSensor ~= nil

    state.navigation.gps =
        modem ~= nil
end

--------------------------------------------------
-- TARGET RELOAD
--------------------------------------------------

local function updateTarget()

    if not fs.exists(
        "target.cfg"
    ) then

        return
    end

    local file =
        fs.open(
            "target.cfg",
            "r"
        )

    if not file then
        return
    end

    local data =
        textutils.unserialize(
            file.readAll()
        )

    file.close()

    if type(data) ~= "table" then
        return
    end

    local revision =
        tonumber(data.revision)

    if revision
        and revision
        == state.target.revision then

        return
    end

    if data.set == false then

        state.target.set = false

        state.target.revision =
            revision
            or (
                state.target.revision + 1
            )

        return
    end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)

    if not x or not y or not z then
        return
    end

    state.target.x = x
    state.target.y = y
    state.target.z = z

    state.target.set = true

    state.target.revision =
        revision
        or (
            state.target.revision + 1
        )
end

--------------------------------------------------
-- GPS UPDATE
--------------------------------------------------

local function updateGPS()

    if not modem then

        state.navigation.status =
            "NO MODEM"

        state.navigation.online =
            false

        return
    end

    local x, y, z =
        gps.locate(
            0.35,
            false
        )

    if not x then

        state.navigation.status =
            "GPS WAIT"

        state.navigation.online =
            false

        return
    end

    local now =
        os.clock()

    if lastX ~= nil
        and lastTime ~= nil then

        local dt =
            now - lastTime

        if dt > 0.001 then

            state.navigation.vx =
                (x - lastX) / dt

            state.navigation.vy =
                (y - lastY) / dt

            state.navigation.vz =
                (z - lastZ) / dt

        end
    end

    state.navigation.x = x
    state.navigation.y = y
    state.navigation.z = z

    state.navigation.altitude = y

    state.navigation.speed =
        math.sqrt(

            state.navigation.vx
                * state.navigation.vx

            +

            state.navigation.vy
                * state.navigation.vy

            +

            state.navigation.vz
                * state.navigation.vz

        )

    state.navigation.verticalSpeed =
        state.navigation.vy

    lastX = x
    lastY = y
    lastZ = z

    lastTime = now
end

--------------------------------------------------
-- ATTITUDE
--------------------------------------------------

local function updateAttitude()

    if navigationTable then

        local orientation =
            safeCall(
                navigationTable,
                "getOrientation"
            )

        if type(orientation) == "table" then

            state.navigation.orientation = {

                tonumber(
                    orientation[1]
                ) or 0,

                tonumber(
                    orientation[2]
                ) or 0,

                tonumber(
                    orientation[3]
                ) or 0,

                tonumber(
                    orientation[4]
                ) or 1
            }

        end

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

    if gimbalSensor then

        local angles =
            safeCall(
                gimbalSensor,
                "getAnglesRad"
            )

        if type(angles) == "table" then

            state.navigation.pitch =
                tonumber(
                    angles[1]
                ) or 0

            state.navigation.roll =
                tonumber(
                    angles[2]
                ) or 0

        end
    end
end

--------------------------------------------------
-- WORLD -> BODY
--------------------------------------------------

local function worldToBody(
    x,
    y,
    z,
    q
)

    local qx =
        q[1] or 0

    local qy =
        q[2] or 0

    local qz =
        q[3] or 0

    local qw =
        q[4] or 1

    local ix =
        qw * x
        + qy * z
        - qz * y

    local iy =
        qw * y
        + qz * x
        - qx * z

    local iz =
        qw * z
        + qx * y
        - qy * x

    local iw =
        -qx * x
        - qy * y
        - qz * z

    local bx =
        ix * qw
        + iw * -qx
        + iy * -qz
        - iz * -qy

    local by =
        iy * qw
        + iw * -qy
        + iz * -qx
        - ix * -qz

    local bz =
        iz * qw
        + iw * -qz
        + ix * -qy
        - iy * -qx

    return bx, by, bz
end

--------------------------------------------------
-- TARGET SOLUTION
--------------------------------------------------

local function updateTargetSolution()

    if not state.target.set then

        state.navigation.distance = 0
        state.navigation.groundDistance = 0
        state.navigation.verticalOffset = 0
        state.navigation.bearing = 0

        state.navigation.bodyX = 0
        state.navigation.bodyY = 0
        state.navigation.bodyZ = 0

        return
    end

    if not state.navigation.gps then
        return
    end

    local dx =
        state.target.x
        - state.navigation.x

    local dy =
        state.target.y
        - state.navigation.y

    local dz =
        state.target.z
        - state.navigation.z

    local groundDistance =
        math.sqrt(
            dx * dx
            + dz * dz
        )

    local distance =
        math.sqrt(
            dx * dx
            + dy * dy
            + dz * dz
        )

    state.navigation.distance =
        distance

    state.navigation.groundDistance =
        groundDistance

    state.navigation.verticalOffset =
        dy

    if groundDistance > 0.001 then

        state.navigation.bearing =
            math.atan2(
                dx,
                dz
            )

    else

        state.navigation.bearing = 0

    end

    local bx, by, bz =
        worldToBody(
            dx,
            dy,
            dz,
            state.navigation.orientation
        )

    state.navigation.bodyX = bx
    state.navigation.bodyY = by
    state.navigation.bodyZ = bz
end

--------------------------------------------------
-- INIT
--------------------------------------------------

function init()

    findPeripherals()

    updateTarget()

end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

function run()

    gpsTimer =
        os.startTimer(
            0.05
        )

    targetTimer =
        os.startTimer(
            TARGET_INTERVAL
        )

    while state.system.running do

        local event, id =
            os.pullEventRaw()

        if event == "timer" then

            if id == gpsTimer then

                findPeripherals()

                updateGPS()

                updateAttitude()

                updateTargetSolution()

                if state.navigation.gps
                    and state.navigation.navTable then

                    state.navigation.online =
                        true

                    state.navigation.status =
                        "ONLINE"

                elseif not state.navigation.gps then

                    state.navigation.online =
                        false

                    state.navigation.status =
                        "NO GPS"

                else

                    state.navigation.online =
                        false

                    state.navigation.status =
                        "NO NAV TABLE"

                end

                state.navigation.lastUpdate =
                    os.clock()

                state.navigation.updateCount =
                    state.navigation.updateCount
                    + 1

                state.system.tick =
                    state.system.tick + 1

                gpsTimer =
                    os.startTimer(
                        GPS_INTERVAL
                    )
            end

            if id == targetTimer then

                updateTarget()

                targetTimer =
                    os.startTimer(
                        TARGET_INTERVAL
                    )
            end
        end

        if event == "terminate" then

            state.system.running =
                false

        end
    end

    state.navigation.online = false
    state.navigation.status = "OFFLINE"
end