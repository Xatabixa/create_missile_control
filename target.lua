-- Target Manager
-- Owns state.target and target.cfg
-- No require()

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

local function readTargetFile()
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

    return {
        x = tonumber(data.x) or 0,
        y = tonumber(data.y) or 0,
        z = tonumber(data.z) or 0,
        set = data.set == true,
        revision = tonumber(data.revision) or 0
    }
end

local function applyTarget(state, data)
    state.target.x = data.x
    state.target.y = data.y
    state.target.z = data.z
    state.target.set = data.set
    state.target.revision = data.revision
end

local function run(state)

    if type(state.target) ~= "table" then
        state.target = defaultTarget()
    end

    -- Load target once at startup.
    applyTarget(
        state,
        readTargetFile()
    )

    while state.system.running do
        sleep(0.5)
    end
end

return {
    run = run
}