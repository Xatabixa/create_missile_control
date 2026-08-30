-- nav_api_test.lua
-- Navigation Table API diagnostic
-- No require() is used.

local nav = peripheral.find("navigation_table")

if not nav then
    print("ERROR: Navigation Table not found.")
    return
end

print("NAVIGATION TABLE FOUND")
print("----------------------")

local methods = peripheral.getMethods(peripheral.getName(nav))

for i, method in ipairs(methods) do
    print(i .. ": " .. method)
end

print("----------------------")
print("Press any key...")

os.pullEvent("key")