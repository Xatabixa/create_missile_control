-- scroll_test.lua

local lines = {}

for i = 1, 200 do
    lines[#lines + 1] =
        string.format(
            "TEST LINE %03d | Navigation system data",
            i
        )
end

local w, h = term.getSize()
local offset = math.max(0, #lines - h)

local function draw()
    term.clear()

    for row = 1, h do
        local index = offset + row

        if index <= #lines then
            term.setCursorPos(1, row)

            local text = lines[index]

            if #text > w then
                text = text:sub(1, w)
            end

            term.write(text)
        end
    end
end

draw()

while true do
    local event, key = os.pullEvent("key")

    if key == keys.up then
        offset = math.max(0, offset - 1)

    elseif key == keys.down then
        offset = math.min(
            math.max(0, #lines - h),
            offset + 1
        )

    elseif key == keys.pageUp then
        offset = math.max(
            0,
            offset - h
        )

    elseif key == keys.pageDown then
        offset = math.min(
            math.max(0, #lines - h),
            offset + h
        )

    elseif key == keys.home then
        offset = 0

    elseif key == keys["end"] then
        offset = math.max(
            0,
            #lines - h
        )

    elseif key == keys.q
        or key == keys.escape then
        break
    end

    draw()
end

term.clear()
term.setCursorPos(1, 1)