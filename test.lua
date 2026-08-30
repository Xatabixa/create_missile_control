-- Peripheral Diagnostic Test
-- READ-ONLY
-- UP/DOWN/PAGE UP/PAGE DOWN = scroll
-- HOME/END = beginning/end
-- Q/ESC = exit

local lines = {}

--------------------------------------------------
-- OUTPUT BUFFER
--------------------------------------------------

local function add(text)
    lines[#lines + 1] = tostring(text)
end

local function section(title)
    add("")
    add("========================================")
    add(title)
    add("========================================")
end

--------------------------------------------------
-- PERIPHERAL INFORMATION
--------------------------------------------------

section("CONNECTED PERIPHERALS")

local names = peripheral.getNames()

if #names == 0 then

    add("NO PERIPHERALS FOUND")

else

    for _, name in ipairs(names) do

        add("")
        add("NAME: " .. tostring(name))

        local types =
            peripheral.getType(name)

        if type(types) == "table" then

            add(
                "TYPE: " ..
                table.concat(
                    types,
                    ", "
                )
            )

        else

            add(
                "TYPE: " ..
                tostring(types)
            )

        end
    end
end

--------------------------------------------------
-- METHODS
--------------------------------------------------

section("AVAILABLE METHODS")

for _, name in ipairs(names) do

    add("")
    add("[" .. tostring(name) .. "]")

    local methods =
        peripheral.getMethods(name)

    if not methods then

        add("  NO METHODS")

    else

        table.sort(methods)

        for _, method in ipairs(methods) do

            add(
                "  " ..
                tostring(method)
            )

        end
    end
end

--------------------------------------------------
-- GPS
--------------------------------------------------

section("GPS")

local x, y, z =
    gps.locate(
        2,
        false
    )

if x then

    add("STATUS: ONLINE")
    add("X: " .. tostring(x))
    add("Y: " .. tostring(y))
    add("Z: " .. tostring(z))

else

    add("STATUS: OFFLINE / NO FIX")

end

--------------------------------------------------
-- TARGET FILE
--------------------------------------------------

section("TARGET")

if fs.exists("target.cfg") then

    local file =
        fs.open(
            "target.cfg",
            "r"
        )

    if file then

        local text =
            file.readAll()

        file.close()

        local data =
            textutils.unserialize(text)

        if type(data) == "table" then

            add(
                "SET: " ..
                tostring(
                    data.set
                )
            )

            add(
                "X: " ..
                tostring(
                    data.x
                )
            )

            add(
                "Y: " ..
                tostring(
                    data.y
                )
            )

            add(
                "Z: " ..
                tostring(
                    data.z
                )
            )

            add(
                "REVISION: " ..
                tostring(
                    data.revision
                    or 0
                )
            )

        else

            add(
                "ERROR: INVALID target.cfg"
            )

        end

    else

        add(
            "ERROR: CANNOT OPEN target.cfg"
        )

    end

else

    add(
        "target.cfg NOT FOUND"
    )

end

--------------------------------------------------
-- SYSTEM FILES
--------------------------------------------------

section("ROCKET FILES")

local files = {
    "launcher.lua",
    "state.lua",
    "target.lua",
    "navigation.lua",
    "guidance.lua",
    "actuator.lua",
    "display.lua"
}

for _, fileName in ipairs(files) do

    add(
        fileName ..
        " : " ..
        (
            fs.exists(fileName)
            and "FOUND"
            or "MISSING"
        )
    )

end

--------------------------------------------------
-- FINISH
--------------------------------------------------

section("TEST COMPLETE")

add("")
add("Use:")
add("UP / DOWN       - one line")
add("PAGE UP / DOWN  - one page")
add("HOME / END      - beginning/end")
add("Q / ESC         - exit")

--------------------------------------------------
-- SCROLL VIEW
--------------------------------------------------

local w, h =
    term.getSize()

local offset =
    math.max(
        0,
        #lines - h + 1
    )

local function draw()

    term.clear()

    for row = 1, h do

        local index =
            offset + row

        if index <= #lines then

            local text =
                lines[index]

            if #text > w then

                text =
                    text:sub(
                        1,
                        w
                    )

            end

            term.setCursorPos(
                1,
                row
            )

            term.write(
                text
            )
        end
    end
end

draw()

--------------------------------------------------
-- INPUT
--------------------------------------------------

while true do

    local event, key =
        os.pullEvent("key")

    if key == keys.up then

        offset =
            math.max(
                0,
                offset - 1
            )

    elseif key == keys.down then

        offset =
            math.min(
                math.max(
                    0,
                    #lines - h
                ),
                offset + 1
            )

    elseif key == keys.pageUp then

        offset =
            math.max(
                0,
                offset - h
            )

    elseif key == keys.pageDown then

        offset =
            math.min(
                math.max(
                    0,
                    #lines - h
                ),
                offset + h
            )

    elseif key == keys.home then

        offset = 0

    elseif key == keys["end"] then

        offset =
            math.max(
                0,
                #lines - h
            )

    elseif key == keys.q
        or key == keys.escape then

        break
    end

    draw()
end

term.clear()
term.setCursorPos(1, 1)