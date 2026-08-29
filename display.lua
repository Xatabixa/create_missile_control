-- Missile Control System Display
-- Arrow keys switch pages
-- I = set impact point
-- Q = shutdown

local state = require("state")

local page = 1
local inputMode = false

--------------------------------------------------
-- NUMBER FORMAT
--------------------------------------------------

local function fmt(value)

    if type(value) ~= "number" then
        return "---"
    end

    return string.format("%.3f", value)

end

--------------------------------------------------
-- ANGLE FORMAT
--------------------------------------------------

local function fmtAngle(value)

    if type(value) ~= "number" then
        return "---"
    end

    return string.format(
        "%.2f",
        math.deg(value)
    )

end

--------------------------------------------------
-- HEADER
--------------------------------------------------

local function header(title)

    term.clear()
    term.setCursorPos(1, 1)

    print("=== MISSILE SYSTEM ===")
    print(title)
    print("----------------------")

end

--------------------------------------------------
-- NAVIGATION PAGE
--------------------------------------------------

local function drawNavigation()

    header("NAVIGATION")

    local n = state.navigation

    print(
        "NAV: " ..
        (n.online and "ONLINE" or "OFFLINE")
    )

    print("")

    print("POS")
    print("X " .. fmt(n.position.x))
    print("Y " .. fmt(n.position.y))
    print("Z " .. fmt(n.position.z))

    print("")

    print("VEL")
    print("X " .. fmt(n.velocity.x))
    print("Y " .. fmt(n.velocity.y))
    print("Z " .. fmt(n.velocity.z))

    print("")

    print(
        "GRAV " ..
        fmt(n.gravity)
    )

    print(
        "HDG " ..
        fmtAngle(n.heading) ..
        " deg"
    )

    print(
        "BRG " ..
        fmtAngle(n.bearing) ..
        " deg"
    )

end

--------------------------------------------------
-- GUIDANCE PAGE
--------------------------------------------------

local function drawGuidance()

    header("GUIDANCE")

    local g = state.guidance
    local n = state.navigation

    print(
        "GUID: " ..
        (g.online and "ONLINE" or "OFFLINE")
    )

    print("")

    print("NAVIGATION")

    print(
        "BRG " ..
        fmtAngle(n.bearing) ..
        " deg"
    )

    print(
        "REL " ..
        fmtAngle(n.relativeAngle) ..
        " deg"
    )

    print(
        "VERT " ..
        fmt(n.elevation)
    )

    print(
        "DIST " ..
        fmt(n.distance)
    )

    print("")

    print("COMMAND")

    print(
        "X " ..
        fmt(g.commandX)
    )

    print(
        "Y " ..
        fmt(g.commandY)
    )

end

--------------------------------------------------
-- ENGINE PAGE
--------------------------------------------------

local function drawEngine()

    header("THRUSTER")

    local t = state.thruster
    local g = state.guidance

    print(
        "ENG: " ..
        (t.online and "ONLINE" or "OFFLINE")
    )

    print("")

    print("COMMAND")

    print(
        "X " ..
        fmt(g.commandX)
    )

    print(
        "Y " ..
        fmt(g.commandY)
    )

    print("")

    print("TARGET VECTOR")

    print(
        "X " ..
        fmt(t.targetVectorX)
    )

    print(
        "Y " ..
        fmt(t.targetVectorY)
    )

    print("")

    print("ACTUAL VECTOR")

    print(
        "X " ..
        fmt(t.vectorX)
    )

    print(
        "Y " ..
        fmt(t.vectorY)
    )

    print("")

    print(
        "POWER " ..
        fmt(t.power)
    )

    print(
        "THRUST " ..
        fmt(t.thrust)
    )

end

--------------------------------------------------
-- SYSTEM PAGE
--------------------------------------------------

local function drawSystem()

    header("SYSTEM")

    print(
        "NAV " ..
        (state.navigation.online
        and "OK"
        or "OFF")
    )

    print(
        "GUID " ..
        (state.guidance.online
        and "OK"
        or "OFF")
    )

    print(
        "ENG " ..
        (state.thruster.online
        and "OK"
        or "OFF")
    )

    print("")

    print("IMPACT POINT")

    if state.target.set then

        print(
            "X " ..
            fmt(state.target.x)
        )

        print(
            "Y " ..
            fmt(state.target.y)
        )

        print(
            "Z " ..
            fmt(state.target.z)
        )

        print("SET")

    else

        print("NOT SET")

    end

    print("")

    print("I: SET POINT")
    print("Q: SHUTDOWN")

end

--------------------------------------------------
-- IMPACT POINT INPUT
--------------------------------------------------

local function inputCoordinate(axis)

    term.clear()
    term.setCursorPos(1, 1)

    print("IMPACT POINT")
    print("----------------------")
    print("")

    print("Enter " .. axis .. " coordinate:")
    print("")

    write("> ")

    local value = read()

    local number = tonumber(value)

    if number == nil then

        print("")
        print("INVALID NUMBER")
        sleep(1)

        return nil

    end

    return number

end

--------------------------------------------------
-- SET IMPACT POINT
--------------------------------------------------

local function setImpactPoint()

    inputMode = true

    local x = inputCoordinate("X")

    if x == nil then
        inputMode = false
        return
    end

    local y = inputCoordinate("Y")

    if y == nil then
        inputMode = false
        return
    end

    local z = inputCoordinate("Z")

    if z == nil then
        inputMode = false
        return
    end

    state.target.x = x
    state.target.y = y
    state.target.z = z

    state.target.set = true

    term.clear()
    term.setCursorPos(1, 1)

    print("IMPACT POINT")
    print("----------------------")
    print("")

    print("SAVED")

    print("")
    print("X " .. fmt(x))
    print("Y " .. fmt(y))
    print("Z " .. fmt(z))

    print("")
    print("Returning...")

    sleep(1)

    inputMode = false

end

--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw()

    if inputMode then
        return
    end

    if page == 1 then

        drawNavigation()

    elseif page == 2 then

        drawGuidance()

    elseif page == 3 then

        drawEngine()

    elseif page == 4 then

        drawSystem()

    end

end

--------------------------------------------------
-- DISPLAY LOOP
--------------------------------------------------

local function displayLoop()

    while state.system.running do

        if not inputMode then

            draw()

        end

        sleep(0.1)

    end

end

--------------------------------------------------
-- INPUT LOOP
--------------------------------------------------

local function inputLoop()

    while state.system.running do

        local _, key =
            os.pullEvent("key")

        if inputMode then

            -- Coordinate input uses read().
            -- Keyboard events are handled by read(),
            -- so navigation keys are ignored here.

        elseif key == keys.left then

            page = 1

        elseif key == keys.up then

            page = 2

        elseif key == keys.right then

            page = 3

        elseif key == keys.down then

            page = 4

        elseif key == keys.i then

            setImpactPoint()

        elseif key == keys.q then

            state.system.running = false

            return

        end

    end

end

--------------------------------------------------
-- RUN
--------------------------------------------------

parallel.waitForAny(
    displayLoop,
    inputLoop
)