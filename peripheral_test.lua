-- Peripheral diagnostic
-- Automatic page display
-- No require() and no keyboard input.

local names = peripheral.getNames()

local perPage = 5
local page = 1
local totalPages = math.ceil(#names / perPage)

while page <= totalPages do
    term.clear()
    term.setCursorPos(1, 1)

    print("=== PERIPHERALS ===")
    print("Page " .. page .. "/" .. totalPages)
    print("Total: " .. #names)
    print("")

    local first = (page - 1) * perPage + 1
    local last = math.min(
        first + perPage - 1,
        #names
    )

    for i = first, last do
        local name = names[i]
        local pType = peripheral.getType(name)

        print(i .. ". " .. name)
        print("   TYPE: " .. tostring(pType))
    end

    sleep(5)

    page = page + 1
end

term.clear()
term.setCursorPos(1, 1)

print("=== DIAGNOSTIC COMPLETE ===")
print("Peripherals: " .. #names)