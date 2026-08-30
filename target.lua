-- Target coordinate storage and control
-- Single-folder ComputerCraft compatible version

local TARGET_FILE = "target.cfg"

local function run(state)

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

        local file =
            fs.open(TARGET_FILE, "r")

        if not file then
            return defaultTarget()
        end

        local content =
            file.readAll()

        file.close()

        local data =
            textutils.unserialize(
                content
            )

        if type(data) ~= "table" then
            return defaultTarget()
        end

        data.x =
            tonumber(data.x) or 0

        data.y =
            tonumber(data.y) or 0

        data.z =
            tonumber(data.z) or 0

        data.set =
            data.set == true

        data.revision =
            tonumber(data.revision) or 0

        return data
    end

    local function apply(data)

        state.target.x = data.x
        state.target.y = data.y
        state.target.z = data.z
        state.target.set = data.set
        state.target.revision =
            data.revision
    end

    local function load()
        local data =
            loadTarget()

        apply(data)

        return data
    end

    load()

    while state.system.running do
        sleep(0.5)
    end
end

return {
    run = run
}