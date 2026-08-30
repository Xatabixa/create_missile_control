-- Universal CC:Tweaked Diagnostic Viewer
-- Runs another Lua program and captures its terminal output.
-- Main missile control scripts are not modified.

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local DEFAULT_PROGRAM = "diagnostic.lua"

--------------------------------------------------
-- TERMINAL BUFFER
--------------------------------------------------

local buffer = {}

local cursorX = 1
local cursorY = 1

local width, height =
    term.getSize()

--------------------------------------------------
-- BUFFER HELPERS
--------------------------------------------------

local function ensureLine(y)

    while #buffer < y do
        buffer[#buffer + 1] = ""
    end

end

local function writeToBuffer(text)

    text = tostring(text)

    ensureLine(cursorY)

    local line =
        buffer[cursorY]

    local before =
        string.sub(line, 1, cursorX - 1)

    local after =
        string.sub(
            line,
            cursorX + #text
        )

    buffer[cursorY] =
        before .. text .. after

    cursorX =
        cursorX + #text

end

local function newLine()

    cursorX = 1
    cursorY = cursorY + 1

    ensureLine(cursorY)

end

--------------------------------------------------
-- CAPTURE TERMINAL
--------------------------------------------------

local captureTerm = {}

setmetatable(
    captureTerm,
    {
        __index = term
    }
)

function captureTerm.write(text)

    writeToBuffer(text)

end

function captureTerm.print(text)

    if text == nil then
        text = ""
    end

    writeToBuffer(text)
    newLine()

end

function captureTerm.setCursorPos(x, y)

    cursorX = x
    cursorY = y

    ensureLine(cursorY)

end

function captureTerm.getCursorPos()

    return cursorX, cursorY

end

function captureTerm.clear()

    buffer = {}

    cursorX = 1
    cursorY = 1

end

--------------------------------------------------
-- RUN PROGRAM
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("UNIVERSAL DIAGNOSTIC VIEWER")
print("===========================")
print("")

write("Program [" .. DEFAULT_PROGRAM .. "]: ")

local input =
    read()

local program

if input == "" then
    program = DEFAULT_PROGRAM
else
    program = input
end

--------------------------------------------------
-- CHECK FILE
--------------------------------------------------

if not fs.exists(program) then

    term.clear()
    term.setCursorPos(1, 1)

    print("ERROR")
    print("")
    print("File not found:")
    print(program)

    print("")
    print("Press any key...")

    os.pullEvent("key")

    return

end

--------------------------------------------------
-- LOAD PROGRAM
--------------------------------------------------

local chunk, err =
    loadfile(program)

if not chunk then

    term.clear()
    term.setCursorPos(1, 1)

    print("LOAD ERROR")
    print("")
    print(tostring(err))

    print("")
    print("Press any key...")

    os.pullEvent("key")

    return

end

--------------------------------------------------
-- EXECUTE WITH CAPTURED TERMINAL
--------------------------------------------------

local oldTerm =
    _ENV.term

_ENV.term =
    captureTerm

local ok, runtimeError =
    pcall(chunk)

_ENV.term =
    oldTerm

--------------------------------------------------
-- ADD RESULT
--------------------------------------------------

if not ok then

    buffer[#buffer + 1] = ""
    buffer[#buffer + 1] = "================================"
    buffer[#buffer + 1] = "RUNTIME ERROR"
    buffer[#buffer + 1] = "================================"
    buffer[#buffer + 1] = tostring(runtimeError)

end

if #buffer == 0 then

    buffer[1] =
        "Program produced no output."

end

--------------------------------------------------
-- SCROLL VIEWER
--------------------------------------------------

local scroll = 0

local function draw()

    term.clear()

    local w, h =
        term.getSize()

    local visible =
        h - 2

    local maxScroll =
        math.max(
            0,
            #buffer - visible
        )

    if scroll > maxScroll then
        scroll = maxScroll
    end

    term.setCursorPos(1, 1)

    write(
        "DIAGNOSTIC  " ..
        (scroll + 1) ..
        "-" ..
        math.min(
            scroll + visible,
            #buffer
        ) ..
        "/" ..
        #buffer
    )

    for i = 1, visible do

        local index =
            scroll + i

        term.setCursorPos(1, i + 1)

        if index <= #buffer then

            local text =
                buffer[index]

            if #text > w then

                text =
                    string.sub(
                        text,
                        1,
                        w
                    )

            end

            write(text)

        end

    end

end

--------------------------------------------------
-- INPUT
--------------------------------------------------

while true do

    draw()

    local _, key =
        os.pullEvent("key")

    local _, h =
        term.getSize()

    local visible =
        h - 2

    local maxScroll =
        math.max(
            0,
            #buffer - visible
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
                scroll - visible
            )

    elseif key == keys.pageDown then

        scroll =
            math.min(
                maxScroll,
                scroll + visible
            )

    elseif key == keys.home then

        scroll = 0

    elseif key == keys["end"] then

        scroll = maxScroll

    elseif key == keys.q then

        break

    end

end

term.clear()
term.setCursorPos(1, 1)

print("Diagnostic viewer closed.")