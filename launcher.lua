-- Missile Control System
-- State and peripheral diagnostic launcher

local state = require("state")

term.clear()
term.setCursorPos(1, 1)

--------------------------------------------------
-- HEADER
--------------------------------------------------

print("MISSILE CONTROL DIAGNOSTIC")
print("==========================")
print("")

--------------------------------------------------
-- STATE TEST
--------------------------------------------------

print("STATE TEST")
print("--------------------------")

if state then
    print("state.lua       OK")
else
    print("state.lua       FAILED")
end

print(
    "system.running  " ..
    tostring(state.system.running)
)

print(
    "system.mode     " ..
    tostring(state.system.mode)
)

print("")

--------------------------------------------------
-- PERIPHERAL LIST
--------------------------------------------------

print("PERIPHERALS")
print("--------------------------")

local names = peripheral.getNames()

if #names == 0 then

    print("NO PERIPHERALS")

else

    for _, name in ipairs(names) do

        local pType =
            peripheral.getType(name)

        print(
            name ..
            " : " ..
            tostring(pType)
        )

    end

end

print("")

--------------------------------------------------
-- NAVIGATION
--------------------------------------------------

print("NAVIGATION TABLE")
print("--------------------------")

local navigation =
    peripheral.find("navigation_table")

if navigation then

    print("FOUND")

    local name =
        peripheral.getName(navigation)

    print(
        "Name: " ..
        tostring(name)
    )

    print("")

    local methods =
        peripheral.getMethods(name)

    print("Methods: " .. #methods)

else

    print("NOT FOUND")

end

print("")

--------------------------------------------------
-- THRUSTER
--------------------------------------------------

print("VECTOR THRUSTER")
print("--------------------------")

local thruster =
    peripheral.find("liquid_vector_thruster")

if thruster then

    print("FOUND")

    local name =
        peripheral.getName(thruster)

    print(
        "Name: " ..
        tostring(name)
    )

    print("")

    local methods =
        peripheral.getMethods(name)

    print("Methods: " .. #methods)

else

    print("NOT FOUND")

end

print("")

--------------------------------------------------
-- MODULE LOADING TEST
--------------------------------------------------

print("MODULE TEST")
print("--------------------------")

local modules = {
    "navigation.lua",
    "guidance.lua",
    "actuator.lua",
    "display.lua"
}

for _, filename in ipairs(modules) do

    local chunk, err =
        loadfile(filename)

    if chunk then

        print(
            filename ..
            " : LOAD OK"
        )

    else

        print(
            filename ..
            " : LOAD FAILED"
        )

        print(
            tostring(err)
        )

    end

end

print("")

--------------------------------------------------
-- STATE VALUES
--------------------------------------------------

print("STATE VALUES")
print("--------------------------")

print(
    "NAV  = " ..
    tostring(state.navigation.online)
)

print(
    "GUID = " ..
    tostring(state.guidance.online)
)

print(
    "ENG  = " ..
    tostring(state.thruster.online)
)

print("")

print("==========================")
print("DIAGNOSTIC FINISHED")
print("")
print("Press any key...")

os.pullEvent("key")