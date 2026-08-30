-- Peripheral diagnostic
-- No require() is used.

print("=== PERIPHERALS ===")
print("")

for _, name in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(name)

    print(name .. " : " .. tostring(pType))

    local methods = peripheral.getMethods(name)

    if methods then
        for _, method in ipairs(methods) do
            print("  - " .. method)
        end
    end

    print("")
end

print("===================")
print("Press any key...")

os.pullEvent("key")