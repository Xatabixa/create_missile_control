-- Target coordinate storage and control
-- Coordinates are stored in target.cfg and mirrored into shared state.

local state = require("state")

local TARGET_FILE = "target.cfg"

local function defaultTarget()
    return {
        x = 0,
        y = 0,
        z = 0,
        set = false,
        revision = 0
    }
end

local function loadTarget()
    if not fs.exists(TARGET_FILE) then
        return defaultTarget()
    end

    local file = fs.open(TARGET_FILE, "r")
    if not file then
        return defaultTarget()
    end

    local content = file.readAll()
    file.close()

    local data = textutils.unserialize(content)
    if type(data) ~= "table" then
        return defaultTarget()
    end

    data.x = tonumber(data.x) or 0
    data.y = tonumber(data.y) or 0
    data.z = tonumber(data.z) or 0
    data.set = data.set == true
    data.revision = tonumber(data.revision) or 0

    return data
end

local function saveTarget(data)
    local file = fs.open(TARGET_FILE, "w")
    if not file then
        return false, "Cannot write target.cfg"
    end

    file.write(textutils.serialize(data))
    file.close()
    return true
end

local function apply(data)
    state.target.x = data.x
    state.target.y = data.y
    state.target.z = data.z
    state.target.set = data.set
    state.target.revision = data.revision
end

local function load()
    local data = loadTarget()
    apply(data)
    return data
end

local function setTarget(x, y, z)
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)

    if not x or not y or not z then
        return false, "Coordinates must be numbers."
    end

    local data = loadTarget()
    data.x = x
    data.y = y
    data.z = z
    data.set = true
    data.revision = (tonumber(data.revision) or 0) + 1

    local ok, err = saveTarget(data)
    if not ok then
        return false, err
    end

    apply(data)
    return true, nil, data.revision
end

local function clearTarget()
    local data = loadTarget()
    data.set = false
    data.revision = (tonumber(data.revision) or 0) + 1

    local ok, err = saveTarget(data)
    if not ok then
        return false, err
    end

    apply(data)
    return true
end

local function run()
    load()

    while state.system.running do
        sleep(0.5)
    end
end

return {
    load = load,
    save = saveTarget,
    set = setTarget,
    clear = clearTarget,
    run = run
}
