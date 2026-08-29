-- Missile system display
-- F1 = Navigation
-- F2 = Guidance
-- F3 = Thruster
-- Q  = Exit

local state = require("state")

local page = 1

--------------------------------------------------
-- FORMAT
--------------------------------------------------

local function fmt(value)

    if type(value) ~= "number" then
        return "---"
    end

    return string.format(
        "%+.3f",
        value
    )
end

--------------------------------------------------
-- HEADER
--------------------------------------------------

local function header(title)

    term.clear()
    term.setCursorPos(1, 1)

    print("=== MISSILE CONTROL SYSTEM ===")
    print("MODE: " .. state.system.mode)
    print("")

    print(
        "[F1] NAV  [F2] GUID  [F3] ENG"
    )

    print("--------------------------------")
    print(title)
    print("--------------------------------")
end

--------------------------------------------------
-- NAVIGATION PAGE
--------------------------------------------------

local function drawNavigation()

    header("NAVIGATION")

    local n =
        state.navigation

    print(
        "Status: " ..
        (n.online and "ONLINE" or "OFFLINE")
    )

    print("")

    print("POSITION")

    print(
        "X: " .. fmt(n.position.x)
    )

    print(
        "Y: " .. fmt(n.position.y)
    )

    print(
        "Z: " .. fmt(n.position.z)
    )

    print("")

    print("VELOCITY")

    print(
        "X: " .. fmt(n.velocity.x)
    )

    print(
        "Y: " .. fmt(n.velocity.y)
    )

    print(
        "Z: " .. fmt(n.velocity.z)
    )

    print("")

    print(
        "Gravity: " ..
        fmt(n.gravity)
    )

    print(
        "Heading: " ..
        fmt(math.deg(n.heading)) ..
        " deg"
    )

    print(
        "Bearing: " ..
        fmt(math.deg(n.bearing)) ..
        " deg"
    )

    print(
        "Distance: " ..
        fmt(n.distance)
    )
end

--------------------------------------------------
-- GUIDANCE PAGE
--------------------------------------------------

local function drawGuidance()

    header("GUIDANCE")

    local g =
        state.guidance

    print(
        "Status: " ..
        (g.online and "ONLINE" or "OFFLINE")
    )

    print("")

    print("NAVIGATION INPUT")

    print(
        "Bearing: " ..
        fmt(
            math.deg(
                state.navigation.bearing
            )
        ) ..
        " deg"
    )

    print("")

    print("COMMAND")

    print(
        "X: " ..
        fmt(g.commandX)
    )

    print(
        "Y: " ..
        fmt(g.commandY)
    )

    print("")

    print("PHYSICAL AXES")

    print("X+ = FORWARD")
    print("X- = BACKWARD")
    print("Y+ = RIGHT")
    print("Y- = LEFT")
end

--------------------------------------------------
-- ENGINE PAGE
--------------------------------------------------

local function drawEngine()

    header("VECTOR THRUSTER")

    local t =
        state.thruster

    print(
        "Status: " ..
        (t.online and "ONLINE" or "OFFLINE")
    )

    print("")

    print("COMMAND")

    print(
        "X: " ..
        fmt(state.guidance.commandX)
    )

    print(
        "Y: " ..
        fmt(state.guidance.commandY)
    )

    print("")

    print("TARGET VECTOR")

    print(
        "X: " ..
        fmt(t.targetVectorX)
    )

    print(
        "Y: " ..
        fmt(t.targetVectorY)
    )

    print("")

    print("ACTUAL VECTOR")

    print(
        "X: " ..
        fmt(t.vectorX)
    )

    print(
        "Y: " ..
        fmt(t.vectorY)
    )

    print("")

    print("Power: " ..
        fmt(t.power)
    )

    print("Thrust: " ..
        fmt(t.thrust)
    )

    print("")
    print("THRUST LOCK: 0")
end

--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw()

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

    while true do

        draw()

        sleep(0.1)

    end

end

--------------------------------------------------
-- INPUT LOOP
--------------------------------------------------

local function inputLoop()

    while true do

        local event, key =
            os.pullEvent("key")

        if key == keys.left then

            page = 1

        elseif key == keys.up then

            page = 2

        elseif key == keys.right then

            page = 3

        elseif key == keys.down then

            page = 4

        elseif key == keys.q then

            state.system.running = false

            return
        end
    end
end

--------------------------------------------------
-- SYSTEM PAGE
--------------------------------------------------

local function drawSystem()

    header("SYSTEM")

    print("MISSILE CONTROL SYSTEM")
    print("")

    print(
        "Mode: " ..
        state.system.mode
    )

    print("")

    print(
        "Navigation: " ..
        (state.navigation.online and
        "ONLINE" or "OFFLINE")
    )

    print(
        "Guidance:   " ..
        (state.guidance.online and
        "ONLINE" or "OFFLINE")
    )

    print(
        "Thruster:   " ..
        (state.thruster.online and
        "ONLINE" or "OFFLINE")
    )

    print("")

    print("THRUST LOCK: 0")

    print("")
    print("--------------------------------")
    print("LEFT  = Navigation")
    print("UP    = Guidance")
    print("RIGHT = Thruster")
    print("DOWN  = System")
    print("Q     = Shutdown")
end

--------------------------------------------------
-- RUN DISPLAY
--------------------------------------------------

parallel.waitForAny(
    displayLoop,
    inputLoop
)