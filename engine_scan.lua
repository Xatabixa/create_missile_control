term.clear()
term.setCursorPos(1, 1)

print("=== ENGINE SCAN ===")
print("")

local count = 0

for _, name in ipairs(peripheral.getNames()) do

    local methods =
        peripheral.getMethods(name)

    local vector = false

    local setVector = false

    local setVectorX = false

    local setVectorY = false


    if type(methods) == "table" then

        for _, method in ipairs(methods) do

            if method == "setVector" then
                setVector = true
            end

            if method == "setVectorX" then
                setVectorX = true
            end

            if method == "setVectorY" then
                setVectorY = true
            end

        end

    end


    vector =
        setVector
        or
        (
            setVectorX
            and
            setVectorY
        )


    if vector then

        count = count + 1

        print(
            count ..
            ": " ..
            name
        )

        print(
            "  TYPE: " ..
            tostring(
                peripheral.getType(name)
            )
        )

        print(
            "  VECTOR API: YES"
        )

        print("")

    end

end


print("--------------------------------")

print(
    "ENGINES FOUND: " ..
    tostring(count)
)

print("")

print("Press any key...")

os.pullEvent("key")