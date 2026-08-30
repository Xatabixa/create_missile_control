-- test.lua

print("=== PERIPHERALS ===")
print("")

for _, name in ipairs(peripheral.getNames()) do
    local types = peripheral.getType(name)

    print("NAME: " .. tostring(name))

    if type(types) == "table" then
        print("TYPE: " .. table.concat(types, ", "))
    else
        print("TYPE: " .. tostring(types))
    end

    print("")
end

print("Press any key...")
os.pullEvent("key")