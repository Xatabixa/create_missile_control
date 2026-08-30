-- Missile Control Diagnostic
-- Scrollable diagnostic information for CC:Tweaked

local lines = {}
local scroll = 0

--------------------------------------------------
-- ADD LINE
--------------------------------------------------

local function add(text)
    lines[#lines + 1] = tostring(text)
end

--------------------------------------------------
-- GET METHODS
--------------------------------------------------

local function getMethods(name)

    local methods =
        peripheral.getMethods(name)

    if not methods then
        return {}
    end

    table.sort(methods)

    return methods
end

--------------------------------------------------
-- COLLECT DIAGNOSTIC DATA
--------------------------------------------------

add("MISSILE CONTROL DIAGNOSTIC")
add("==========================")
add("")

--------------------------------------------------
-- PERIPHERALS
--------------------------------------------------

add("CONNECTED PERIPHERALS")
add("----------------------")

local names =
    peripheral.getNames()

if #names == 0 then

    add("NO PERIPHERALS FOUND")

else

    for _, name in ipairs(names) do

        local pType =
            peripheral.getType(name)

        if type(pType) == "table" then

            add(
                name ..
                " -> " ..
                table.concat(pType, ", ")
            )

        else

            add(
                name ..
                " -> " ..
                tostring(pType)
            )

        end
    end
end

add("")
add("----------------------")

--------------------------------------------------
-- NAVIGATION TABLE
--------------------------------------------------

local navigation =
    peripheral.find("navigation_table")

if navigation then

    add("NAVIGATION TABLE: FOUND")

    local name =
        peripheral.getName(navigation)

    add("Name: " .. tostring(name))

    add("")
    add("NAVIGATION METHODS")
    add("------------------")

    local methods =
        getMethods(name)

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

    local name =
        peripheral.getName(thruster)

    add("Name: " .. tostring(name))

    add("")
    add("THRUSTER METHODS")
    add("----------------")

    local methods =
        getMethods(name)

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
add("==========================")
add("END OF DIAGNOSTIC")

--------------------------------------------------
-- DRAW SCREEN
--------------------------------------------------

local function draw()

    term.clear()

    local width, height =
        term.getSize()

    local visibleLines =
        height - 3

    local maxScroll =
        math.max(
            0,
            #lines - visibleLines
        )

    if scroll > maxScroll then
        scroll = maxScroll
    end

    term.setCursorPos(1, 1)

    print(
        "DIAGNOSTIC " ..
        "[" ..
        (scroll + 1) ..
        "-" ..
        math.min(
            scroll + visibleLines,
            #lines
        ) ..
        "/" ..
        #lines ..
        "]"
    )

    term.setCursorPos(1, 2)

    print(
        string.rep("-", width)
    )

    for i = 1, visibleLines do

        local index =
            scroll + i

        term.setCursorPos(1, i + 2)

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

            write(text)

        end

    end

end

--------------------------------------------------
-- MAIN INPUT LOOP
--------------------------------------------------

draw()

while true do

    local event, key =
        os.pullEvent("key")

    local keyName =
        keys.getName(key)

    local _, height =
        term.getSize()

    local visibleLines =
        height - 3

    local maxScroll =
        math.max(
            0,
            #lines - visibleLines
        )

    --------------------------------------------------
    -- DEBUG
    --------------------------------------------------

    -- Uncomment this if keyboard input needs testing:
    -- term.setCursorPos(1, 1)
    -- print("KEY: " .. tostring(keyName))

    --------------------------------------------------
    -- UP
    --------------------------------------------------

    if keyName == "up" then

        scroll =
            math.max(
                0,
                scroll - 1
            )

    --------------------------------------------------
    -- DOWN
    --------------------------------------------------

    elseif keyName == "down" then

        scroll =
            math.min(
                maxScroll,
                scroll + 1
            )

    --------------------------------------------------
    -- PAGE UP
    --------------------------------------------------

    elseif keyName == "pageUp" then

        scroll =
            math.max(
                0,
                scroll - visibleLines
            )

    --------------------------------------------------
    -- PAGE DOWN
    --------------------------------------------------

    elseif keyName == "pageDown" then

        scroll =
            math.min(
                maxScroll,
                scroll + visibleLines
            )

    --------------------------------------------------
    -- HOME
    --------------------------------------------------

    elseif keyName == "home" then

        scroll = 0

    --------------------------------------------------
    -- END
    --------------------------------------------------

    elseif keyName == "end" then

        scroll = maxScroll

    --------------------------------------------------
    -- EXIT
    --------------------------------------------------

    elseif keyName == "q" then

        break

    end

    draw()

end

--------------------------------------------------
-- EXIT
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("Diagnostic closed.")