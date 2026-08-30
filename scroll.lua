-- scroll.lua
-- Simple terminal scrollback viewer

local history = {}
local maxHistory = 500

local oldTerm = term.current()

--------------------------------------------------
-- HISTORY BUFFER
--------------------------------------------------

local function addLine(text)
    history[#history + 1] = text

    if #history > maxHistory then
        table.remove(history, 1)
    end
end

--------------------------------------------------
-- REDRAW
--------------------------------------------------

local function redraw(offset)
    local w, h = oldTerm.getSize()

    oldTerm.setCursorBlink(false)
    oldTerm.clear()

    local lastLine =
        math.max(
            1,
            #history - offset
        )

    local firstLine =
        math.max(
            1,
            lastLine - h + 1
        )

    local row = 1

    for i = firstLine, lastLine do

        oldTerm.setCursorPos(
            1,
            row
        )

        oldTerm.write(
            tostring(
                history[i]
            )
        )

        row = row + 1

        if row > h then
            break
        end
    end

    oldTerm.setCursorPos(
        1,
        h
    )
end

--------------------------------------------------
-- TERMINAL WRAPPER
--------------------------------------------------

local scrollTerm = {}

setmetatable(
    scrollTerm,
    {
        __index = oldTerm
    }
)

local cursorX = 1
local cursorY = 1

function scrollTerm.write(text)

    text = tostring(text)

    local lines =
        {}

    for line in (
        text .. "\n"
    ):gmatch("(.-)\n") do

        lines[#lines + 1] =
            line
    end

    for _, line in ipairs(lines) do
        addLine(line)
    end

    oldTerm.write(text)
end

function scrollTerm.print(...)

    local args = {...}

    local text = ""

    for i, value in ipairs(args) do

        if i > 1 then
            text = text .. "\t"
        end

        text =
            text .. tostring(value)
    end

    addLine(text)

    oldTerm.write(text)
    oldTerm.write("\n")
end

--------------------------------------------------
-- MAIN
--------------------------------------------------

term.redirect(scrollTerm)

local scrollOffset = 0

print("Scrollback terminal")
print("Use UP / DOWN to scroll.")
print("Press Q to exit.")

while true do

    local event, key =
        os.pullEvent()

    if event == "key" then

        if key == keys.up then

            scrollOffset =
                math.min(
                    scrollOffset + 1,
                    math.max(
                        0,
                        #history - 1
                    )
                )

            redraw(
                scrollOffset
            )

        elseif key == keys.down then

            scrollOffset =
                math.max(
                    0,
                    scrollOffset - 1
                )

            redraw(
                scrollOffset
            )

        elseif key == keys.q then

            break
        end
    end
end

term.redirect(oldTerm)

oldTerm.clear()
oldTerm.setCursorPos(1, 1)

print("Scrollback disabled.")