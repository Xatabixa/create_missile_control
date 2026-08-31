-- Sensor / Peripheral Diagnostic Tool
-- CC:Tweaked
--
-- Shows all connected peripherals, their methods,
-- and attempts to read common sensor values.
--
-- CONTROLS:
--   UP       = scroll up
--   DOWN     = scroll down
--   PAGE UP  = scroll 10 lines up
--   PAGE DOWN= scroll 10 lines down
--   HOME     = top
--   END      = bottom
--   R        = rescan
--   Q        = exit
--
-- IMPORTANT:
-- This program NEVER calls setVector().
-- Thrusters are read-only during this test.

--------------------------------------------------
-- TERMINAL
--------------------------------------------------

local termWidth,
termHeight =
    term.getSize()


--------------------------------------------------
-- DATA
--------------------------------------------------

local lines = {}

local scroll = 0


--------------------------------------------------
-- ADD LINE
--------------------------------------------------

local function add(text)

    lines[#lines + 1] =
        tostring(
            text or ""
        )

end


--------------------------------------------------
-- SEPARATOR
--------------------------------------------------

local function separator()

    add("----------------------------------------")

end


--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function safeCall(
    device,
    method,
    ...
)

    if not device then

        return false,
            nil,
            "NO DEVICE"

    end


    local fn =
        device[method]


    if type(fn) ~= "function" then

        return false,
            nil,
            "NO METHOD"

    end


    local ok,
    a,
    b,
    c,
    d =
        pcall(
            fn,
            ...
        )


    if not ok then

        return false,
            nil,
            tostring(a)

    end


    return true,
        {
            a,
            b,
            c,
            d
        },
        nil

end


--------------------------------------------------
-- VALUE TO TEXT
--------------------------------------------------

local function valueText(
    value
)

    if value == nil then

        return "nil"

    end


    if type(value) == "table" then

        local parts = {}


        for k, v in pairs(value) do

            local converted


            if type(v) == "table" then

                converted =
                    textutils.serialize(
                        v
                    )

            else

                converted =
                    tostring(v)

            end


            table.insert(
                parts,
                tostring(k) ..
                "=" ..
                converted
            )

        end


        table.sort(
            parts
        )


        return "{" ..
            table.concat(
                parts,
                ", "
            ) ..
            "}"

    end


    return tostring(value)

end


--------------------------------------------------
-- READ METHOD
--------------------------------------------------

local function read(
    name,
    device,
    method
)

    local ok,
    result,
    errorText =
        safeCall(
            device,
            method
        )


    if not ok then

        add(
            method ..
            " = ERROR: " ..
            tostring(
                errorText
            )
        )


        return

    end


    add(
        method ..
        " = " ..
        valueText(
            result[1]
        )
    )


    if result[2] ~= nil
        then

        add(
            "  arg2 = " ..
            valueText(
                result[2]
            )
        )

    end


    if result[3] ~= nil
        then

        add(
            "  arg3 = " ..
            valueText(
                result[3]
            )
        )

    end


    if result[4] ~= nil
        then

        add(
            "  arg4 = " ..
            valueText(
                result[4]
            )
        )

    end

end


--------------------------------------------------
-- TEST ONE PERIPHERAL
--------------------------------------------------

local function inspectPeripheral(
    name
)

    local pType =
        peripheral.getType(
            name
        )


    local device =
        peripheral.wrap(
            name
        )


    add("")
    add("========================================")
    add("PERIPHERAL: " .. name)
    add("TYPE: " .. tostring(pType))
    add("========================================")


    if not device then

        add("ERROR: peripheral.wrap() failed")
        separator()

        return

    end


    --------------------------------------------------
    -- METHODS
    --------------------------------------------------

    add("")
    add("METHODS:")


    local methods =
        peripheral.getMethods(
            name
        )


    if type(methods) ==
        "table" then

        table.sort(
            methods
        )


        for _, method in ipairs(
            methods
        ) do

            add(
                "  " ..
                method
            )

        end

    else

        add("  <unable to read methods>")

    end


    --------------------------------------------------
    -- BASIC PERIPHERAL INFORMATION
    --------------------------------------------------

    add("")
    add("BASIC TESTS:")


    read(
        name,
        device,
        "getType"
    )


    --------------------------------------------------
    -- NAVIGATION TABLE
    --------------------------------------------------

    if pType ==
        "navigation_table" then

        add("")
        add("NAVIGATION TABLE DATA:")
        separator()


        read(
            name,
            device,
            "hasTarget"
        )


        read(
            name,
            device,
            "getHeadingRad"
        )


        read(
            name,
            device,
            "getBearingRad"
        )


        read(
            name,
            device,
            "getRelativeAngleRad"
        )


        read(
            name,
            device,
            "getDistanceToTarget"
        )


        read(
            name,
            device,
            "getVerticalOffsetToTarget"
        )


        read(
            name,
            device,
            "getClosureRate"
        )


        read(
            name,
            device,
            "getPosition"
        )


        read(
            name,
            device,
            "getVelocity"
        )


        read(
            name,
            device,
            "getOrientation"
        )

    end


    --------------------------------------------------
    -- ALTITUDE SENSOR
    --------------------------------------------------

    if pType ==
        "altitude_sensor" then

        add("")
        add("ALTITUDE SENSOR DATA:")
        separator()


        read(
            name,
            device,
            "getHeight"
        )


        read(
            name,
            device,
            "getVerticalSpeed"
        )


        read(
            name,
            device,
            "getAirPressure"
        )

    end


    --------------------------------------------------
    -- GIMBAL SENSOR
    --------------------------------------------------

    if pType ==
        "gimbal_sensor" then

        add("")
        add("GIMBAL SENSOR DATA:")
        separator()


        read(
            name,
            device,
            "getAnglesRad"
        )


        read(
            name,
            device,
            "getAngularRatesRad"
        )


        read(
            name,
            device,
            "getGravity"
        )


        read(
            name,
            device,
            "getLinearAcceleration"
        )


        read(
            name,
            device,
            "getPosition"
        )


        read(
            name,
            device,
            "getOrientation"
        )

    end


    --------------------------------------------------
    -- VELOCITY SENSOR
    --------------------------------------------------

    if pType ==
        "velocity_sensor" then

        add("")
        add("VELOCITY SENSOR DATA:")
        separator()


        read(
            name,
            device,
            "getAxis"
        )


        read(
            name,
            device,
            "getVelocity"
        )


        read(
            name,
            device,
            "getSpeed"
        )


        read(
            name,
            device,
            "getPosition"
        )

    end


    --------------------------------------------------
    -- THRUSTER
    --------------------------------------------------

    if pType ==
        "liquid_vector_thruster"
        or
        pType ==
        "vector_thruster" then

        add("")
        add("THRUSTER DATA:")
        separator()


        -- READ ONLY.
        -- setVector() is NEVER called.


        read(
            name,
            device,
            "getVectorX"
        )


        read(
            name,
            device,
            "getVectorY"
        )


        read(
            name,
            device,
            "getTargetVectorX"
        )


        read(
            name,
            device,
            "getTargetVectorY"
        )


        read(
            name,
            device,
            "getPower"
        )


        read(
            name,
            device,
            "getThrust"
        )


        read(
            name,
            device,
            "getFluidLevel"
        )

    end


    --------------------------------------------------
    -- GENERIC TEST OF EVERY GETTER
    --------------------------------------------------

    add("")
    add("GETTER METHODS:")


    if type(methods) ==
        "table" then

        for _, method in ipairs(
            methods
        ) do

            if method:sub(
                1,
                3
            ) == "get"
            or
            method:sub(
                1,
                3
            ) == "has" then

                local alreadyRead =
                    false


                --------------------------------------------------
                -- Avoid repeating common methods.
                --------------------------------------------------

                if method ==
                    "getHeadingRad"
                    or
                    method ==
                    "getBearingRad"
                    or
                    method ==
                    "getRelativeAngleRad"
                    or
                    method ==
                    "getDistanceToTarget"
                    or
                    method ==
                    "getVerticalOffsetToTarget"
                    or
                    method ==
                    "getClosureRate"
                    or
                    method ==
                    "getHeight"
                    or
                    method ==
                    "getVerticalSpeed"
                    or
                    method ==
                    "getAirPressure"
                    or
                    method ==
                    "getAnglesRad"
                    or
                    method ==
                    "getAngularRatesRad"
                    or
                    method ==
                    "getGravity"
                    or
                    method ==
                    "getLinearAcceleration"
                    or
                    method ==
                    "getAxis"
                    or
                    method ==
                    "getVelocity"
                    or
                    method ==
                    "getVectorX"
                    or
                    method ==
                    "getVectorY"
                    or
                    method ==
                    "getTargetVectorX"
                    or
                    method ==
                    "getTargetVectorY"
                    or
                    method ==
                    "getPower"
                    or
                    method ==
                    "getThrust"
                    or
                    method ==
                    "hasTarget" then

                    alreadyRead =
                        true

                end


                if not alreadyRead then

                    local ok,
                    result,
                    errorText =
                        safeCall(
                            device,
                            method
                        )


                    if ok then

                        add(
                            method ..
                            " = " ..
                            valueText(
                                result[1]
                            )
                        )

                    else

                        add(
                            method ..
                            " = ERROR: " ..
                            tostring(
                                errorText
                            )
                        )

                    end

                end

            end

        end

    end


    separator()

end


--------------------------------------------------
-- SCAN
--------------------------------------------------

local function scan()

    lines = {}

    scroll = 0


    add("MISSILE CONTROL SENSOR DIAGNOSTICS")
    add("")


    local names =
        peripheral.getNames()


    add(
        "PERIPHERALS FOUND: " ..
        tostring(
            #names
        )
    )


    add("")


    if #names == 0 then

        add("NO PERIPHERALS FOUND.")

        return

    end


    --------------------------------------------------
    -- LIST
    --------------------------------------------------

    add("CONNECTED PERIPHERALS:")


    for i, name in ipairs(
        names
    ) do

        add(
            tostring(i) ..
            ". " ..
            name ..
            " [" ..
            tostring(
                peripheral.getType(
                    name
                )
            ) ..
            "]"
        )

    end


    --------------------------------------------------
    -- DETAILED DATA
    --------------------------------------------------

    for _, name in ipairs(
        names
    ) do

        inspectPeripheral(
            name
        )

    end


    add("")
    add("END OF REPORT")
    add("")
    add("UP/DOWN = SCROLL")
    add("PAGE UP/DOWN = FAST SCROLL")
    add("HOME/END = TOP/BOTTOM")
    add("R = RESCAN")
    add("Q = EXIT")

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


    local visibleLines =
        termHeight - 1


    local maxScroll =
        math.max(
            0,
            #lines -
            visibleLines
        )


    if scroll < 0 then
        scroll = 0
    end


    if scroll > maxScroll then
        scroll = maxScroll
    end


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    term.write(
        "SENSOR TEST  "
    )


    term.write(
        "[" ..
        tostring(
            scroll
        ) ..
        "/" ..
        tostring(
            maxScroll
        ) ..
        "]"
    )


    --------------------------------------------------
    -- CONTENT
    --------------------------------------------------

    for row = 2,
        termHeight do

        local index =
            scroll +
            row -
            1


        term.setCursorPos(
            1,
            row
        )


        term.clearLine()


        if lines[index] then

            local text =
                lines[index]


            if #text > termWidth then

                text =
                    text:sub(
                        1,
                        termWidth
                    )

            end


            term.write(
                text
            )

        end

    end

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

scan()

draw()


while true do

    local event,
    key =
        os.pullEvent(
            "key"
        )


    --------------------------------------------------
    -- UP
    --------------------------------------------------

    if key ==
        keys.up then

        scroll =
            scroll - 1

        draw()


    --------------------------------------------------
    -- DOWN
    --------------------------------------------------

    elseif key ==
        keys.down then

        scroll =
            scroll + 1

        draw()


    --------------------------------------------------
    -- PAGE UP
    --------------------------------------------------

    elseif key ==
        keys.pageUp then

        scroll =
            scroll -
            math.max(
                1,
                termHeight -
                2
            )

        draw()


    --------------------------------------------------
    -- PAGE DOWN
    --------------------------------------------------

    elseif key ==
        keys.pageDown then

        scroll =
            scroll +
            math.max(
                1,
                termHeight -
                2
            )

        draw()


    --------------------------------------------------
    -- HOME
    --------------------------------------------------

    elseif key ==
        keys.home then

        scroll =
            0

        draw()


    --------------------------------------------------
    -- END
    --------------------------------------------------

    elseif key ==
        keys["end"] then

        scroll =
            #lines

        draw()


    --------------------------------------------------
    -- RESCAN
    --------------------------------------------------

    elseif key ==
        keys.r then

        scan()

        draw()


    --------------------------------------------------
    -- EXIT
    --------------------------------------------------

    elseif key ==
        keys.q then

        term.clear()

        term.setCursorPos(
            1,
            1
        )

        break

    end

end