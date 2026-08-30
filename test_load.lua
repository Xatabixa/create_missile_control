-- Rocket directory loader test

term.clear()
term.setCursorPos(1, 1)

print("ROCKET FILE TEST")
print("================")
print("")

local files = {
    "state.lua",
    "navigation.lua",
    "guidance.lua",
    "actuator.lua",
    "display.lua",
    "launcher.lua"
}

for _, filename in ipairs(files) do

    local path =
        "/rocket/" .. filename

    if not fs.exists(path) then

        print(filename .. " : NOT FOUND")

    else

        local chunk, err =
            loadfile(path)

        if chunk then

            print(filename .. " : LOAD OK")

        else

            print(filename .. " : LOAD FAILED")
            print("  " .. tostring(err))

        end

    end

end

print("")
print("Press any key...")

os.pullEvent("key")