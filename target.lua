-- Impact Point Configuration
--
-- Usage:
--
-- target
-- target set X Y Z
-- target show
-- target clear

local TARGET_FILE = "target.cfg"

--------------------------------------------------
-- LOAD
--------------------------------------------------

local function loadTarget()

    if not fs.exists(TARGET_FILE) then

        return {
            x = 0,
            y = 0,
            z = 0,
            set = false,
            revision = 0
        }

    end

    local file =
        fs.open(
            TARGET_FILE,
            "r"
        )

    if not file then
        error(
            "Cannot open target.cfg"
        )
    end

    local data =
        textutils.unserialize(
            file.readAll()
        )

    file.close()

    if type(data) ~= "table" then

        return {
            x = 0,
            y = 0,
            z = 0,
            set = false,
            revision = 0
        }

    end

    return data
end

--------------------------------------------------
-- SAVE
--------------------------------------------------

local function saveTarget(data)

    local file =
        fs.open(
            TARGET_FILE,
            "w"
        )

    if not file then
        error(
            "Cannot write target.cfg"
        )
    end

    file.write(
        textutils.serialize(data)
    )

    file.close()
end

--------------------------------------------------
-- SET TARGET
--------------------------------------------------

local function setTarget(x, y, z)

    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)

    if not x or not y or not z then

        print(
            "ERROR: coordinates must be numbers."
        )

        return
    end

    local data =
        loadTarget()

    data.x = x
    data.y = y
    data.z = z

    data.set = true

    data.revision =
        (tonumber(data.revision) or 0)
        + 1

    saveTarget(data)

    print("")
    print("====================")
    print("IMPACT POINT SET")
    print("====================")
    print("X: " .. x)
    print("Y: " .. y)
    print("Z: " .. z)
    print("REVISION: " .. data.revision)
    print("")
end

--------------------------------------------------
-- CLEAR TARGET
--------------------------------------------------

local function clearTarget()

    local data =
        loadTarget()

    data.set = false

    data.revision =
        (tonumber(data.revision) or 0)
        + 1

    saveTarget(data)

    print("")
    print("IMPACT POINT CLEARED")
    print("")
end

--------------------------------------------------
-- SHOW TARGET
--------------------------------------------------

local function showTarget()

    local data =
        loadTarget()

    print("")
    print("====================")
    print("IMPACT POINT")
    print("====================")

    if data.set == false then

        print("NOT SET")

    else

        print(
            "X: " ..
            tostring(data.x)
        )

        print(
            "Y: " ..
            tostring(data.y)
        )

        print(
            "Z: " ..
            tostring(data.z)
        )

        print(
            "REVISION: " ..
            tostring(data.revision or 0)
        )

    end

    print("")
end

--------------------------------------------------
-- INTERACTIVE MODE
--------------------------------------------------

local function interactive()

    print("")
    print("====================")
    print("IMPACT POINT")
    print("====================")

    write("X: ")
    local x = read()

    write("Y: ")
    local y = read()

    write("Z: ")
    local z = read()

    setTarget(x, y, z)
end

--------------------------------------------------
-- COMMAND LINE
--------------------------------------------------

local args = {...}

if #args == 0 then

    interactive()
    return

end

local command =
    string.lower(
        tostring(args[1])
    )

if command == "set" then

    setTarget(
        args[2],
        args[3],
        args[4]
    )

elseif command == "show" then

    showTarget()

elseif command == "clear" then

    clearTarget()

else

    print("")
    print("TARGET COMMANDS")
    print("")
    print("target")
    print("target set X Y Z")
    print("target show")
    print("target clear")
    print("")

end