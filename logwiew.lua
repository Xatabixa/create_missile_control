-- Simple log viewer for CC:Tweaked
-- UP / DOWN    - scroll one line
-- PAGE UP/DOWN - scroll one screen
-- HOME         - top
-- END          - bottom
-- Q / ESC      - exit

local fileName = "test.log"

if not fs.exists(fileName) then
    print("No log file: " .. fileName)
    return
end

local function loadLines()
    local file = fs.open(fileName, "r")

    if not file then
        return {}
    end

    local lines = {}

    while true do
        local line = file.readLine()

        if line == nil then
            break
        end

        lines[#lines + 1] = line
    end

    file.close()

    return lines
end

local lines = loadLines()

local w, h = term.getSize()

local top = math.max(
    1,
    #lines - h + 1
)

local function draw()
    term.setCursorBlink(false)
    term.clear()

    for row = 1, h do
        local index = top + row - 1

        if index <= #lines then
            term.setCursorPos(1, row)

            local text = lines[index]

            if #text > w then
                text = text:sub(1, w)
            end

            term.write(text)
        end
    end

    -- Position indicator
    term.setCursorPos(1, h)

    local percent = 100

    if #lines > h then
        percent =
            math.floor(
                ((top - 1) /
                (#lines - h)) * 100
            )
    end

    term.write(
        "[" ..
        tostring(percent) ..
        "%]  " ..
        tostring(top) ..
        "/" ..
        tostring(#lines)
    )
end

draw()

while true do

    local event, key =
        os.pullEvent("key")

    if key == keys.up then

        top =
            math.max(
                1,
                top - 1
            )

    elseif key == keys.down then

        top =
            math.min(
                math.max(
                    1,
                    #lines - h + 1
                ),
                top + 1
            )

    elseif key == keys.pageUp then

        top =
            math.max(
                1,
                top - (h - 1)
            )

    elseif key == keys.pageDown then

        top =
            math.min(
                math.max(
                    1,
                    #lines - h + 1
                ),
                top + (h - 1)
            )

    elseif key == keys.home then

        top = 1

    elseif key == keys["end"] then

        top =
            math.max(
                1,
                #lines - h + 1
            )

    elseif key == keys.q
        or key == keys.escape then

        break
    end

    draw()
end

term.clear()
term.setCursorPos(1, 1)
term.setCursorBlink(true)