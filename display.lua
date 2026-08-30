-- Missile Control Display

local state = ...

local screen = nil

local width = 0
local height = 0

local refreshTimer

--------------------------------------------------
-- SCREEN
--------------------------------------------------

local function openScreen()

    screen =
        peripheral.find(
            "monitor"
        )

    if not screen then
        screen = term.current()
    end

    if type(
        screen.setTextScale
    ) == "function" then

        pcall(
            function()

                screen.setTextScale(
                    0.5
                )

            end
        )
    end

    width, height =
        screen.getSize()

    screen.setBackgroundColor(
        colors.black
    )

    screen.setTextColor(
        colors.white
    )
end

--------------------------------------------------
-- CLEAR
--------------------------------------------------

local function clear()

    screen.setBackgroundColor(
        colors.black
    )

    screen.clear()

    screen.setCursorPos(
        1,
        1
    )
end

--------------------------------------------------
-- TEXT
--------------------------------------------------

local function line(
    row,
    text
)

    if row < 1
        or row > height then

        return
    end

    local output =
        tostring(
            text or ""
        )

    if #output > width then

        output =
            output:sub(
                1,
                width
            )
    end

    screen.setCursorPos(
        1,
        row
    )

    screen.clearLine()

    screen.write(
        output
    )
end

--------------------------------------------------
-- NUMBER
--------------------------------------------------

local function fmt(
    value,
    digits
)

    value =
        tonumber(value)

    if not value then
        return "---"
    end

    return string.format(
        "%." ..
        tostring(
            digits or 1
        ) ..
        "f",
        value
    )
end

--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw()

    clear()

    line(
        1,
        "MISSILE CONTROL"
    )

    line(
        2,
        "=============================="
    )

    line(
        3,
        "SYSTEM: " ..
        tostring(
            state.system.status
        )
    )

    line(
        4,
        "MODE:   " ..
        tostring(
            state.system.mode
        )
    )

    line(
        5,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ON"
            or "OFF"
        )
    )

    --------------------------------------------------
    -- NAVIGATION
    --------------------------------------------------

    line(
        6,
        ""
    )

    line(
        7,
        "NAVIGATION: " ..
        tostring(
            state.navigation.status
        )
    )

    line(
        8,
        "POS X: " ..
        fmt(
            state.navigation.x,
            1
        )
    )

    line(
        9,
        "POS Y: " ..
        fmt(
            state.navigation.y,
            1
        )
    )

    line(
        10,
        "POS Z: " ..
        fmt(
            state.navigation.z,
            1
        )
    )

    line(
        11,
        "ALT: " ..
        fmt(
            state.navigation.altitude,
            1
        )
        ..
        "  V: "
        ..
        fmt(
            state.navigation.verticalSpeed,
            1
        )
    )

    line(
        12,
        "SPEED: " ..
        fmt(
            state.navigation.speed,
            1
        )
        ..
        "  HDG: "
        ..
        fmt(
            math.deg(
                state.navigation.heading
            ),
            1
        )
    )

    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    line(
        13,
        ""
    )

    line(
        14,
        "TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

    line(
        15,
        "X: " ..
        fmt(
            state.target.x,
            1
        )
        ..
        "  Y: "
        ..
        fmt(
            state.target.y,
            1
        )
    )

    line(
        16,
        "Z: " ..
        fmt(
            state.target.z,
            1
        )
    )

    line(
        17,
        "DIST: " ..
        fmt(
            state.navigation.distance,
            1
        )
    )

    --------------------------------------------------
    -- GUIDANCE
    --------------------------------------------------

    line(
        18,
        "GUIDANCE: " ..
        tostring(
            state.guidance.status
        )
    )

    line(
        19,
        "YAW: " ..
        fmt(
            math.deg(
                state.guidance.yawError
            ),
            1
        )
        ..
        "  PITCH: "
        ..
        fmt(
            math.deg(
                state.guidance.pitchError
            ),
            1
        )
    )

    line(
        20,
        "CMD X: " ..
        fmt(
            state.guidance.commandX,
            2
        )
        ..
        "  Y: "
        ..
        fmt(
            state.guidance.commandY,
            2
        )
    )

    --------------------------------------------------
    -- ACTUATOR
    --------------------------------------------------

    line(
        21,
        "ACTUATOR: " ..
        tostring(
            state.actuator.status
        )
    )

    line(
        22,
        "VECTOR X: " ..
        fmt(
            state.actuator.vectorX,
            2
        )
        ..
        " Y: "
        ..
        fmt(
            state.actuator.vectorY,
            2
        )
    )

    line(
        23,
        "THRUST: " ..
        fmt(
            state.actuator.thrust,
            2
        )
        ..
        " POWER: "
        ..
        fmt(
            state.actuator.power,
            2
        )
    )

    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

    line(
        24,
        "Q = SHUTDOWN"
    )

    --------------------------------------------------
    -- ERROR
    --------------------------------------------------

    if state.system.error then

        line(
            height,
            "ERROR: " ..
            tostring(
                state.system.error
            )
        )
    end
end

--------------------------------------------------
-- INIT
--------------------------------------------------

function init()

    openScreen()

    draw()

end

--------------------------------------------------
-- RUN
--------------------------------------------------

function run()

    openScreen()

    refreshTimer =
        os.startTimer(
            0.10
        )

    while state.system.running do

        local event, a, b, c =
            os.pullEventRaw()

        --------------------------------------------------
        -- REFRESH
        --------------------------------------------------

        if event == "timer"
            and a == refreshTimer then

            draw()

            refreshTimer =
                os.startTimer(
                    0.10
                )
        end

        --------------------------------------------------
        -- KEYBOARD SHUTDOWN
        --------------------------------------------------

        if event == "key" then

            if a == keys.q then

                state.system.status =
                    "SHUTTING DOWN"

                state.system.running =
                    false

                break
            end
        end

        --------------------------------------------------
        -- MONITOR TOUCH
        --------------------------------------------------

        if event == "monitor_touch" then

            if c >= height - 1 then

                state.system.status =
                    "SHUTTING DOWN"

                state.system.running =
                    false

                break
            end
        end

        --------------------------------------------------
        -- TERMINATE
        --------------------------------------------------

        if event == "terminate" then

            state.system.running =
                false

            break
        end
    end

    draw()
end