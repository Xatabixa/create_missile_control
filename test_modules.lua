-- Simple Rocket Module Test
-- This test does not use state.lua.

term.clear()
term.setCursorPos(1, 1)

print("ROCKET MODULE TEST")
print("==================")
print("")

--------------------------------------------------
-- TEST NAVIGATION PERIPHERAL
--------------------------------------------------

print("NAVIGATION TABLE")
print("----------------")

local navigation =
    peripheral.find("navigation_table")

if navigation then

    print("FOUND")

    local name =
        peripheral.getName(navigation)

    print("Name: " .. name)

    local methods =
        peripheral.getMethods(name)

    print("Methods: " .. #methods)

else

    print("NOT FOUND")

end

print("")

--------------------------------------------------
-- TEST THRUSTER PERIPHERAL
--------------------------------------------------

print("VECTOR THRUSTER")
print("----------------")

local thruster =
    peripheral.find("liquid_vector_thruster")

if thruster then

    print("FOUND")

    local name =
        peripheral.getName(thruster)

    print("Name: " .. name)

    local methods =
        peripheral.getMethods(name)

    print("Methods: " .. #methods)

else

    print("NOT FOUND")

end

print("")

--------------------------------------------------
-- TEST FILES
--------------------------------------------------

print("MODULE FILES")
print("----------------")

local files = {
    "navigation.lua",
    "actuator.lua",
    "guidance.lua",
    "display.lua"
}

for _, filename in ipairs(files) do

    if fs.exists(filename) then

        print(
            filename .. " : EXISTS"
        )

    else

        print(
            filename .. " : MISSING"
        )

    end

end

print("")
print("==================")
print("TEST COMPLETE")
print("")
print("Press any key...")

os.pullEvent("key")