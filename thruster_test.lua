-- Liquid Vector Thruster Bench Test
-- CC:Tweaked
--
-- SAFETY:
-- This test ONLY changes vector direction.
-- It NEVER calls:
--   setPower()
--   setPowerNormalized()
--   setThrust()
--   setThrustNormalized()
--
-- Default test magnitude:
--   +/- 0.20
--
-- CONTROLS:
--   1 = X +0.20
--   2 = X -0.20
--   3 = Y +0.20
--   4 = Y -0.20
--   5 = CENTER
--   R = RESCAN
--   Q = EXIT
--
-- Before testing:
--   Freeze the rocket.
--
-- IMPORTANT:
-- All detected vector thrusters receive the same command.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local TEST_VALUE = 0.20

local REFRESH_TIME = 0.2


--------------------------------------------------
-- STATE
--------------------------------------------------

local running = true

local vectorX = 0
local vectorY = 0

local thrusters = {}

local lastAction = "CENTER"


--------------------------------------------------
-- SAFE VECTOR COMMAND
--------------------------------------------------

local function setVector(
    device,
    x,
    y
)

    if not device then

        return false,
            "DEVICE INVALID"

    end


    local methods =
        peripheral.getMethods(
            device.__name
        )


    local hasSetVector =
        false


    local hasX =
        false


    local hasY =
        false


    if type(methods) ==
        "table" then

        for _, method in ipairs(
            methods
        ) do

            if method ==
                "setVector" then

                hasSetVector =
                    true


            elseif method ==
                "setVectorX" then

                hasX =
                    true


            elseif method ==
                "setVectorY" then

                hasY =
                    true

            end

        end

    end


    --------------------------------------------------
    -- PREFERRED API
    --------------------------------------------------

    if hasSetVector then

        local ok,
            err =
            pcall(
                function()

                    device.setVector(
                        x,
                        y
                    )

                end
            )


        if ok then

            return true, nil

        end


        return false,
            tostring(err)

    end


    --------------------------------------------------
    -- FALLBACK API
    --------------------------------------------------

    if hasX and hasY then

        local ok,
            err =
            pcall(
                function()

                    device.setVectorX(
                        x
                    )

                    device.setVectorY(
                        y
                    )

                end
            )


        if ok then

            return true, nil

        end


        return false,
            tostring(err)

    end


    return false,
        "NO VECTOR METHOD"

end


--------------------------------------------------
-- FIND THRUSTERS
--------------------------------------------------

local function scan()

    thrusters = {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        local pType =
            peripheral.getType(
                name
            )


        local methods =
            peripheral.getMethods(
                name
            )


        local vectorAPI =
            false


        if type(methods) ==
            "table" then

            local hasSet =
                false

            local hasX =
                false

            local hasY =
                false


            for _, method in ipairs(
                methods
            ) do

                if method ==
                    "setVector" then

                    hasSet =
                        true

                elseif method ==
                    "setVectorX" then

                    hasX =
                        true

                elseif method ==
                    "setVectorY" then

                    hasY =
                        true

                end

            end


            vectorAPI =
                hasSet
                or
                (
                    hasX
                    and
                    hasY
                )

        end


        if vectorAPI then

            local device =
                peripheral.wrap(
                    name
                )


            if device then

                -- Store the name directly on the
                -- wrapped peripheral so setVector()
                -- can inspect its API.
                device.__name =
                    name


                table.insert(
                    thrusters,
                    {
                        name = name,
                        type = pType,
                        device = device
                    }
                )

            end

        end

    end

end


--------------------------------------------------
-- READ ACTUAL VECTOR
--------------------------------------------------

local function readVector(
    entry
)

    if not entry
        or
        not entry.device then

        return nil, nil

    end


    local device =
        entry.device


    local x = nil
    local y = nil


    --------------------------------------------------
    -- X
    --------------------------------------------------

    if type(
        device.getVectorX
    ) == "function" then

        local ok,
            value =
            pcall(
                device.getVectorX
            )


        if ok then

            x =
                tonumber(
                    value
                )

        end

    end


    --------------------------------------------------
    -- Y
    --------------------------------------------------

    if type(
        device.getVectorY
    ) == "function" then

        local ok,
            value =
            pcall(
                device.getVectorY
            )


        if ok then

            y =
                tonumber(
                    value
                )

        end

    end


    return x, y

end


--------------------------------------------------
-- APPLY TO ALL
--------------------------------------------------

local function applyVector(
    x,
    y
)

    vectorX = x
    vectorY = y


    local success =
        0


    local errors = {}


    for _, entry in ipairs(
        thrusters
    ) do

        local ok,
            err =
            setVector(
                entry.device,
                x,
                y
            )


        if ok then

            success =
                success + 1

        else

            errors[
                entry.name
            ] =
                err
                or
                "UNKNOWN"

        end

    end


    lastAction =
        "SET X=" ..
        string.format(
            "%.2f",
            x
        ) ..
        " Y=" ..
        string.format(
            "%.2f",
            y
        )


    return success,
        errors

end


--------------------------------------------------
-- CENTER
--------------------------------------------------

local function center()

    applyVector(
        0,
        0
    )


    lastAction =
        "CENTER"

end


--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw()

    term.clear()

    term.setCursorPos(
        1,
        1
    )


    local width,
        height =
        term.getSize()


    print(
        "=== VECTOR THRUSTER TEST ==="
    )


    print(
        ""
    )


    print(
        "Rocket should be FROZEN"
    )


    print(
        "No thrust is generated."
    )


    print(
        ""
    )


    print(
        "ENGINES: " ..
        tostring(
            #thrusters
        )
    )


    print(
        ""
    )


    print(
        "COMMAND"
    )


    print(
        "X = " ..
        string.format(
            "%.2f",
            vectorX
        )
    )


    print(
        "Y = " ..
        string.format(
            "%.2f",
            vectorY
        )
    )


    print(
        ""
    )


    print(
        "ACTUAL ENGINE VECTORS"
    )


    --------------------------------------------------
    -- SHOW ALL ENGINES
    --------------------------------------------------

    for i, entry in ipairs(
        thrusters
    ) do

        if 10 + i >
            height then

            break

        end


        local x, y =
            readVector(
                entry
            )


        if x == nil then

            xText =
                "---"

        else

            xText =
                string.format(
                    "%.3f",
                    x
                )

        end


        if y == nil then

            yText =
                "---"

        else

            yText =
                string.format(
                    "%.3f",
                    y
                )

        end


        write(
            "E" ..
            tostring(i) ..
            " " ..
            entry.name ..
            " X=" ..
            xText ..
            " Y=" ..
            yText
        )

    end


    --------------------------------------------------
    -- FOOTER
    --------------------------------------------------

    local footerRow =
        math.min(
            height - 4,
            22
        )


    if footerRow < 1 then
        footerRow = 1
    end


    term.setCursorPos(
        1,
        footerRow
    )


    print(
        "LAST: " ..
        lastAction
    )


    print(
        "1:+X 2:-X 3:+Y 4:-Y 5:CENTER"
    )


    print(
        "R:RESCAN Q:EXIT"
    )


    print(
        ""
    )


    print(
        "TEST VALUE: +/-" ..
        string.format(
            "%.2f",
            TEST_VALUE
        )
    )

end


--------------------------------------------------
-- INITIAL SCAN
--------------------------------------------------

scan()

center()

draw()


--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while running do

    local event,
        key =
        os.pullEvent(
            "key"
        )


    --------------------------------------------------
    -- +X
    --------------------------------------------------

    if key ==
        keys.one then

        applyVector(
            TEST_VALUE,
            0
        )


        draw()


    --------------------------------------------------
    -- -X
    --------------------------------------------------

    elseif key ==
        keys.two then

        applyVector(
            -TEST_VALUE,
            0
        )


        draw()


    --------------------------------------------------
    -- +Y
    --------------------------------------------------

    elseif key ==
        keys.three then

        applyVector(
            0,
            TEST_VALUE
        )


        draw()


    --------------------------------------------------
    -- -Y
    --------------------------------------------------

    elseif key ==
        keys.four then

        applyVector(
            0,
            -TEST_VALUE
        )


        draw()


    --------------------------------------------------
    -- CENTER
    --------------------------------------------------

    elseif key ==
        keys.five then

        center()

        draw()


    --------------------------------------------------
    -- RESCAN
    --------------------------------------------------

    elseif key ==
        keys.r then

        center()

        scan()

        draw()


    --------------------------------------------------
    -- EXIT
    --------------------------------------------------

    elseif key ==
        keys.q then

        center()

        running =
            false

    end

end


--------------------------------------------------
-- FINAL SAFETY
--------------------------------------------------

for _, entry in ipairs(
    thrusters
) do

    setVector(
        entry.device,
        0,
        0
    )

end


term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "VECTOR THRUSTER TEST FINISHED"
)