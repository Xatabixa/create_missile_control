-- Missile Control Display

local state = require("state")

local page = 1
local inputMode = false

--------------------------------------------------
-- FORMAT NUMBER
--------------------------------------------------

local function number(value)

    if type(value) ~= "number" then
        return "---"
    end

    return string.format("%.2f", value)
end

--------------------------------------------------
-- FORMAT ANGLE
--------------------------------------------------

local function angle(value)

    if type(value) ~= "number" then
        return "---"
    end

    return string.format(
        "%.2f°",
        math.deg(value)
    )
end

--------------------------------------------------
-- HEADER
--------------------------------------------------

local function header(title)

    term.clear()
    term.setCursorPos(1, 1)

    print("MISSILE CONTROL")
    print(title)
    print("----------------")

end

--------------------------------------------------
-- NAVIGATION PAGE
--------------------------------------------------

local function navigationPage()

    header("NAVIGATION")

    local n =
        state.navigation

    print(
        "STATUS: " ..
        n.status
    )

    print("")

    print(
        "BEARING   " ..
        angle(n.bearing)
    )

    print(
        "HEADING   " ..
        angle(n.heading)
    )

    print(
        "RELATIVE  " ..
        angle(n.relativeAngle)
    )

    print(
        "VERTICAL  " ..
        number(n.verticalOffset)
    )

    print(
        "DISTANCE  " ..
        number(n.distance)
    )

    print(
        "CLOSURE   " ..
        number(n.closureRate)
    )

    print("")

    print(
        "UPDATES   " ..
        tostring(n.updateCount)
    )

end

--------------------------------------------------
-- GUIDANCE PAGE
--------------------------------------------------

local function guidancePage()

    header("GUIDANCE")

    local g =
        state.guidance

    print(
        "STATUS: " ..
        g.status
    )

    print("")

    print("COMMAND VECTOR")

    print(
        "X   " ..
        number(g.commandX)
    )

    print(
        "Y   " ..
        number(g.commandY)
    )

    print("")

    print(
        "UPDATES   " ..
        tostring(g.updateCount)
    )

end

--------------------------------------------------
-- THRUSTER PAGE
--------------------------------------------------

local function thrusterPage()

    header("THRUSTER")

    local t =
        state.thruster

    print(
        "STATUS: " ..
        t.status
    )

    print("")

    print(
        "POWER     " ..
        number(t.power)
    )

    print(
        "THRUST    " ..
        number(t.thrust)
    )

    print("")

    print("ACTUAL VECTOR")

    print(
        "X   " ..
        number(t.vectorX)
    )

    print(
        "Y   " ..
        number(t.vectorY)
    )

    print("")

    print("TARGET VECTOR")

    print(
        "X   " ..
        number(t.targetVectorX)
    )

    print(
        "Y   " ..
        number(t.targetVectorY)
    )

end

--------------------------------------------------
-- SYSTEM PAGE
--------------------------------------------------

local function systemPage()

    header("SYSTEM")

    print(
        "MODE: " ..
        state.system.mode
    )

    print(
        "STATUS: " ..
        state.system.status
    )

    print("")

    print("SUBSYSTEMS")

    print(
        "NAVIGATION  " ..
        state.navigation.status
    )

    print(
        "GUIDANCE    " ..
        state.guidance.status
    )

    print(
        "THRUSTER    " ..
        state.thruster.status
    )

    print("")

    print("IMPACT POINT")

    if state.impactPoint.set then

        print(
            "X " ..
            number(state.impactPoint.x)
        )

        print(
            "Y " ..
            number(state.impactPoint.y)
        )

        print(
            "Z " ..
            number(state.impactPoint.z)
        )

    else

        print("NOT SET")

    end

    print("")
    print("I - SET IMPACT POINT")
    print("Q - SHUTDOWN")

end

--------------------------------------------------
-- INPUT COORDINATE
--------------------------------------------------

local function inputCoordinate(axis)

    term.clear()
    term.setCursorPos(1, 1)

    print("SET IMPACT POINT")
    print("----------------")
    print("")
    print(
        "Enter " ..
        axis ..
        " coordinate:"
    )
    print("")

    write("> ")

    local value =
        tonumber(read())

    if value == nil then

        print("")
        print("INVALID VALUE")

        sleep(1)

        return nil
    end

    return value
end

--------------------------------------------------
-- SET IMPACT POINT
--------------------------------------------------

local function setImpactPoint()

    inputMode = true

    local x =
        inputCoordinate("X")

    if x == nil then
        inputMode = false
        return
    end

    local y =
        inputCoordinate("Y")

    if y == nil then
        inputMode = false
        return
    end

    local z =
        inputCoordinate("Z")

    if z == nil then
        inputMode = false
        return
    end

    state.impactPoint.x = x
    state.impactPoint.y = y
    state.impactPoint.z = z

    state.impactPoint.set = true

    term.clear()
    term.setCursorPos(1, 1)

    print("IMPACT POINT")
    print("----------------")
    print("")
    print("POINT SAVED")
    print("")
    print("X " .. number(x))
    print("Y " .. number(y))
    print("Z " .. number(z))

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

        navigationPage()

    elseif page == 2 then

        guidancePage()

    elseif page == 3 then

        thrusterPage()

    elseif page == 4 then

        systemPage()

    end

end

--------------------------------------------------
-- DISPLAY LOOP
--------------------------------------------------

local function displayLoop()

    while state.system.running do

        draw()

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

        if not inputMode then

            if key == keys.up then

                page = 1

            elseif key == keys.left then

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

end

--------------------------------------------------
-- START
--------------------------------------------------

state.system.status = "ONLINE"

parallel.waitForAny(
    displayLoop,
    inputLoop
)