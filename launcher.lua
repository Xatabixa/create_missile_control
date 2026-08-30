-- Missile Control - File Diagnostic

term.clear()
term.setCursorPos(1, 1)

print("MISSILE CONTROL")
print("FILE DIAGNOSTIC")
print("================")
print("")

local files = {
    "state.lua",
    "navigation.lua",
    "guidance.lua",
    "actuator.lua",
    "display.lua"
}

for _, filename in ipairs(files) do

    print("")
    print("FILE: " .. filename)
    print("----------------")

    if not fs.exists(filename) then

        print("NOT FOUND")

    else

        print("EXISTS")

        local chunk, err =
            loadfile(filename)

        if chunk then

            print("LOAD: OK")

        else

            print("LOAD: FAILED")
            print("")
            print(tostring(err))

        end

    end

end

print("")
print("================")
print("END")
print("")
print("Press any key...")

os.pullEvent("key")