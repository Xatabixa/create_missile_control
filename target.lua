-- Impact point configuration

local state =
    require("state")

term.clear()
term.setCursorPos(1, 1)

print("=== IMPACT POINT ===")
print("")
print("Enter impact coordinates.")
print("")

write("X: ")
local x = tonumber(read())

write("Y: ")
local y = tonumber(read())

write("Z: ")
local z = tonumber(read())

if not x or not y or not z then

    print("")
    print("ERROR: Invalid coordinates.")

    sleep(2)

    return
end

--------------------------------------------------
-- SAVE IMPACT POINT
--------------------------------------------------

state.impactPoint.x = x
state.impactPoint.y = y
state.impactPoint.z = z

state.impactPoint.set = true

--------------------------------------------------
-- DISPLAY RESULT
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("=== IMPACT POINT ===")
print("")
print("Coordinates set:")
print("")
print("X: " .. x)
print("Y: " .. y)
print("Z: " .. z)
print("")
print("Impact point is READY.")

sleep(2)
