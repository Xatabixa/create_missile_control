-- Missile Control System Diagnostic Launcher

term.clear()
term.setCursorPos(1, 1)

print("MISSILE CONTROL DIAGNOSTIC")
print("==========================")
print("")

--------------------------------------------------
-- LIST PERIPHERALS
--------------------------------------------------

local names = peripheral.getNames()

print("CONNECTED PERIPHERALS:")
print("")

if #names == 0 then

    print("NO PERIPHERALS FOUND")

else

    for _, name in ipairs(names) do

        local pType =
            peripheral.getType(name)

        print(
            name ..
            " -> " ..
            tostring(pType)
        )

    end

end

print("")
print("--------------------------")
print("")

--------------------------------------------------
-- FIND EXPECTED DEVICES
--------------------------------------------------

local navigation =
    peripheral.find("navigation_table")

local thruster =
    peripheral.find("liquid_vector_thruster")

if navigation then

    print("NAVIGATION TABLE: FOUND")

else

    print("NAVIGATION TABLE: NOT FOUND")

end

if thruster then

    print("VECTOR THRUSTER: FOUND")

else

    print("VECTOR THRUSTER: NOT FOUND")

end

print("")
print("--------------------------")
print("")

--------------------------------------------------
-- TEST METHODS
--------------------------------------------------

if navigation then

    print("NAVIGATION METHODS:")

    local methods =
        peripheral.getMethods(
            peripheral.getName(navigation)
        )

    if methods then

        for _, method in ipairs(methods) do

            print("  " .. method)

        end

    end

else

    print("Navigation Table unavailable.")

end

print("")
print("--------------------------")
print("")

if thruster then

    print("THRUSTER METHODS:")

    local methods =
        peripheral.getMethods(
            peripheral.getName(thruster)
        )

    if methods then

        for _, method in ipairs(methods) do

            print("  " .. method)

        end

    end

else

    print("Vector Thruster unavailable.")

end

print("")
print("==========================")
print("DIAGNOSTIC COMPLETE")
print("")
print("Press any key...")

os.pullEvent("key")