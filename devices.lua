-- DEVICE LIST
-- No input required.

term.clear()
term.setCursorPos(1, 1)

print("=== DEVICE LIST ===")
print("")

local names = peripheral.getNames()

print("FOUND: " .. #names)
print("")

for i, name in ipairs(names) do
    print(i .. ": " .. name)
    print("   TYPE: " .. tostring(peripheral.getType(name)))
end

print("")
print("=== END ===")