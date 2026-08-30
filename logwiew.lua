-- scroll.lua

local w, h = term.getSize()

term.clear()
term.setCursorPos(1, 1)

for i = 1, 100 do
    print("Test line " .. i)
end

-- Wait for scrolling commands
while true do
    local event, key = os.pullEvent("key")

    if key == keys.up then
        term.scroll(-1)

    elseif key == keys.down then
        term.scroll(1)

    elseif key == keys.pageUp then
        term.scroll(-(h - 1))

    elseif key == keys.pageDown then
        term.scroll(h - 1)

    elseif key == keys.home then
        -- CC:Tweaked has no direct "scroll to top",
        -- so repeatedly scroll upward.
        term.scroll(-1000)

    elseif key == keys["end"] then
        term.scroll(1000)

    elseif key == keys.q or key == keys.escape then
        break
    end
end