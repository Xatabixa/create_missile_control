-- Peripheral diagnostic
-- Shows all peripherals page by page.
-- No require() is used.

local names = peripheral.getNames()
local index = 1
local perPage = 10

while index <= #names do
    term.clear()
    term.setCursorPos(1, 1)

    print("=== PERIPHERALS ===")
    print("Page " ..
        math.ceil(index / perPage) ..
        "/" ..
        math.ceil(#names / perPage))
    print("")

    local last = math.min(
        index + perPage - 1,
        #names
    )

    for i = index, last do
        local name = names[i]
        local pType = peripheral.getType(name)

        print(i .. ". " ..
            name ..
            " [" ..
            tostring(pType) ..
            "]")
    end

    print("")
    print("N = next page")
    print("Q = quit")

    local event, key = os.pullEvent("key")

    if key == keys.n then
        index = index + perPage

    elseif key == keys.q then
        break
    end
end

term.clear()
term.setCursorPos(1, 1)

print("Diagnostic finished.")