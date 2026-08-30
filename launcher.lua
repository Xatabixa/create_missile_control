-- Missile Control Diagnostic
-- Scrollable diagnostic information

local lines = {}
local scroll = 0

--------------------------------------------------
-- ADD LINE
--------------------------------------------------

local function add(text)
    table.insert(lines, tostring(text))
end

--------------------------------------------------
-- SAFE PERIPHERAL METHODS
--------------------------------------------------

local function getMethods(name)
    local methods = peripheral.getMethods(name)

    if not methods then
        return {}
    end

    table.sort(methods)

    return methods
end

--------------------------------------------------
-- COLLECT INFORMATION
--------------------------------------------------

add("MISSILE CONTROL DIAGNOSTIC")
add("==========================")
add("")

--------------------------------------------------
-- PERIPHERALS
--------------------------------------------------

add("CONNECTED PERIPHERALS")
add("----------------------")

local names = peripheral.getNames()

if #names == 0 then

    add("NO PERIPHERALS FOUND")

else

    for _, name in ipairs(names) do

        local types = peripheral.getType(name)

        if type(types) == "table" then

            add(
                name ..
                " -> " ..
                table.concat(types, ", ")
            )

        else

            add(
                name ..
                " -> " ..
                tostring(types)
            )

        end

    end

end

add("")
add("----------------------")

--------------------------------------------------
-- NAVIGATION
--------------------------------------------------

local navigation =
    peripheral.find("navigation_table")

if navigation then

    add("NAVIGATION TABLE: FOUND")

    local navigationName =
        peripheral.getName(navigation)

    add(
        "Name: " ..
        tostring(navigationName)
    )

    add("")
    add("NAVIGATION METHODS")
    add("------------------")

    local methods =
        getMethods(navigationName)

    if #methods == 0 then

        add("NO METHODS")

    else

        for _, method in ipairs(methods) do
            add(method)
        end

    end

else

    add("NAVIGATION TABLE: NOT FOUND")

end

add("")
add("----------------------")

--------------------------------------------------
-- THRUSTER
--------------------------------------------------

local thruster =
    peripheral.find("liquid_vector_thruster")

if thruster then

    add("VECTOR THRUSTER: FOUND")

    local thrusterName =
        peripheral.getName(thruster)

    add(
        "Name: " ..
        tostring(thrusterName)
    )

    add("")
    add("THRUSTER METHODS")
    add("----------------")

    local methods =
        getMethods(thrusterName)

    if #methods == 0 then

        add("NO METHODS")

    else

        for _, method in ipairs(methods) do
            add(method)
        end

    end

else

    add("VECTOR THRUSTER: NOT FOUND")

end

add("")
add("----------------------")

--------------------------------------------------
-- DEVICE TEST
--------------------------------------------------

add("METHOD TEST")
add("-----------")

if navigation then

    local name =
        peripheral.getName(navigation)

    add("Navigation device: " .. name)

    local methods =
        getMethods(name)

    for _, method in ipairs(methods) do

        local ok, result =
            pcall(function()
                return peripheral.call(name, method)
            end)

        if ok then

            if type(result) == "table" then
                add(
                    method ..
                    " = TABLE"
                )
            elseif result == nil then
                add(
                    method ..
                    " = nil"
                )
            else
                add(
                    method ..
                    " = " ..
                    tostring(result)
                )
            end

        else

            add(
                method ..
                " = ERROR"
            )

        end

    end

else

    add("Navigation device unavailable.")

end

add("")
add("----------------------")

if thruster then

    local name =
        peripheral.getName(thruster)

    add(
        "Thruster device: " ..
        name
    )

else

    add("Thruster device unavailable.")

end

add("")
add("==========================")
add("END OF DIAGNOSTIC")

--------------------------------------------------
-- DISPLAY
--------------------------------------------------

local function draw()

    term.clear()

    local width, height =
        term.getSize()

    term.setCursorPos(1, 1)

    print(
        "DIAGNOSTIC  [" ..
        (scroll + 1) ..
        "-" ..
        math.min(
            scroll + height - 2,
            #lines
        ) ..
        "/" ..
        #lines ..
        "]"
    )

    print(
        string.rep("-", width)
    )

    for i = 1, height - 2 do

        local index =
            scroll + i

        if index <= #lines then

            local text =
                lines[index]

            if #text > width then

                text =
                    string.sub(
                        text,
                        1,
                        width
                    )

            end

            term.setCursorPos(1, i + 2)
            print(text)

        end

    end

    term.setCursorPos(1, height)

    print(
        "UP/DOWN Scroll | PgUp/PgDn Page | Q Exit"
    )

end

--------------------------------------------------
-- INPUT
--------------------------------------------------

local function input()

    while true do

        local _, key =
            os.pullEvent("key")

        local _, height =
            term.getSize()

        local maxScroll =
            math.max(
                0,
                #lines - (height - 2)
            )

        if key == keys.up then

            scroll =
                math.max(
                    0,
                    scroll - 1
                )

        elseif key == keys.down then

            scroll =
                math.min(
                    maxScroll,
                    scroll + 1
                )

        elseif key == keys.pageUp then

            scroll =
                math.max(
                    0,
                    scroll - (height - 2)
                )

        elseif key == keys.pageDown then

            scroll =
                math.min(
                    maxScroll,
                    scroll + (height - 2)
                )

        elseif key == keys.home then

            scroll = 0

        elseif key == keys["end"] then

            scroll = maxScroll

        elseif key == keys.q then

            return

        end

        draw()

    end

end

--------------------------------------------------
-- START
--------------------------------------------------

draw()
input()

term.clear()
term.setCursorPos(1, 1)

print("Diagnostic closed.")