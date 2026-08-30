-- test.lua
-- Peripheral detection test
-- UP / DOWN / PAGE UP / PAGE DOWN = scroll
-- Q / ESC = exit

local lines = {}

local function add(text)
    lines[#lines + 1] = tostring(text)
end

add("========================================")
add("     PERIPHERAL DETECTION TEST")
add("========================================")
add("")

local names = peripheral.getNames()

if #names == 0 then
    add("NO PERIPHERALS FOUND")
else
    add("FOUND " .. #names .. " PERIPHERAL(S)")
    add("")

    for i, name in ipairs(names) do
        local types = peripheral.getType(name)

        if type(types) == "table" then
            types = table.concat(types, ", ")
        end

        add(
            string.format(
                "%02d. %s",
                i,
                tostring(name)
            )
        )

        add(
            "    TYPE: " ..
            tostring(types)
        )

        add("")
    end
end

add("========================================")
add("END OF TEST")
add("========================================")
add("")
add("UP/DOWN     - scroll")
add("PAGE UP/DOWN - page")
add("Q/ESC       - exit")

--------------------------------------------------
-- SCROLL VIEW
--------------------------------------------------

local w, h = term.getSize()

local offset = math.max(
    0,
    #lines - h
)

local function draw()
    term.clear()

    for row = 1, h do
        local index = offset + row

        if index <= #lines then
            local text = lines[index]

            if #text > w then
                text = text:sub(1, w)
            end

            term.setCursorPos(1, row)
            term.write(text)
        end
    end
end

draw()

--------------------------------------------------
-- INPUT
--------------------------------------------------

while true do
    local _, key = os.pullEvent("key")

    if key == keys.up then

        offset = math.max(
            0,
            offset - 1
        )

    elseif key == keys.down then

        offset = math.min(
            math.max(
                0,
                #lines - h
            ),
            offset + 1
        )

    elseif key == keys.pageUp then

        offset = math.max(
            0,
            offset - h
        )

    elseif key == keys.pageDown then

        offset = math.min(
            math.max(
                0,
                #lines - h
            ),
            offset + h
        )

    elseif key == keys.home then

        offset = 0

    elseif key == keys["end"] then

        offset = math.max(
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