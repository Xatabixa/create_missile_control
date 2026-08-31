for _, name in ipairs(peripheral.getNames()) do
    print("=== " .. name .. " ===")
    print(peripheral.getType(name))

    local methods = peripheral.getMethods(name)

    if methods then
        for _, method in ipairs(methods) do
            print("  " .. method)
        end
    end

    print("")
end