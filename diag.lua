-- Universal CC:Tweaked Diagnostic Viewer
-- Does not modify any existing program.

--------------------------------------------------
-- FIND FILE
--------------------------------------------------

local function findFile(filename)

    -- Current directory
    if fs.exists(filename) then
        return filename
    end

    -- Root directory
    local rootPath =
        "/" .. filename

    if fs.exists(rootPath) then
        return rootPath
    end

    -- Search one level deep
    local rootEntries =
        fs.list("/")

    for _, entry in ipairs(rootEntries) do

        local path =
            "/" .. entry

        if fs.isDir(path) then

            local candidate =
                path .. "/" .. filename

            if fs.exists(candidate) then
                return candidate
            end

        end

    end

    return nil

end

--------------------------------------------------
-- SELECT PROGRAM
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("UNIVERSAL DIAGNOSTIC VIEWER")
print("===========================")
print("")

print("Current directory:")
print(fs.getDir(shell.getRunningProgram()))
print("")

print("Enter program name or path.")
print("Example: launcher.lua")
print("Example: /missile/launcher.lua")
print("")

write("> ")

local input =
    read()

if input == "" then

    input = "launcher.lua"

end

--------------------------------------------------
-- RESOLVE PATH
--------------------------------------------------

local program =
    findFile(input)

if not program then

    term.clear()
    term.setCursorPos(1, 1)

    print("FILE NOT FOUND")
    print("================")
    print("")
    print("Requested:")
    print(input)

    print("")
    print("Files in current directory:")

    local currentDir =
        fs.getDir(
            shell.getRunningProgram()
        )

    if currentDir == "" then
        currentDir = "/"
    end

    local entries =
        fs.list(currentDir)

    for _, entry in ipairs(entries) do

        print("  " .. entry)

    end

    print("")
    print("Press any key...")

    os.pullEvent("key")

    return

end

--------------------------------------------------
-- LOAD
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("FOUND")
print("================")
print("")
print(program)
print("")

local chunk, err =
    loadfile(program)

if not chunk then

    print("LOAD FAILED")
    print("")
    print(tostring(err))

    print("")
    print("Press any key...")

    os.pullEvent("key")

    return

end

print("LOAD OK")
print("")
print("Running diagnostic...")
print("")

--------------------------------------------------
-- CAPTURE OUTPUT
--------------------------------------------------

local buffer = {}

local cursorX = 1
local cursorY = 1

local captureTerm = {}

setmetatable(
    captureTerm,
    {
        __index = term
    }
)

local function ensureLine(y)

    while #buffer < y do
        buffer[#buffer + 1] = ""
    end

end

function captureTerm.write(text)

    text = tostring(text)

    ensureLine(cursorY)

    local line =
        buffer[cursorY]

    local before =
        string.sub(
            line,
            1,
            cursorX - 1
        )

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

function captureTerm.print(text)

    if text == nil then
        text = ""
    end

    captureTerm.write(text)

    cursorX = 1
    cursorY = cursorY + 1

    ensureLine(cursorY)

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
-- RUN
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
-- ERROR
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
        "Program produced no terminal output."

end

--------------------------------------------------
-- VIEWER
--------------------------------------------------

local scroll = 0

while true do

    term.clear()

    local width, height =
        term.getSize()

    local visible =
        height - 2

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
        "DIAGNOSTIC " ..
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

    local _, key =
        os.pullEvent("key")

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