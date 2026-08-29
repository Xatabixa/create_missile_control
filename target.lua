-- Impact point configuration

local state = require("state")

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

state.target.x = x
state.target.y = y
state.target.z = z

state.target.set = true

term.clear()
term.setCursorPos(1, 1)

print("=== IMPACT POINT ===")
print("")

print("Coordinates set:")
print("X: " .. x)
print("Y: " .. y)
print("Z: " .. z)

print("")
print("Impact point is READY.")

sleep(2)