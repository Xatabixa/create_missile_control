-- Guidance subsystem.
--
-- Converts target direction in body coordinates
-- into normalized vector commands.

local state = ...

local MAX_COMMAND = 1.0

local YAW_GAIN = 1.8
local PITCH_GAIN = 1.8

local MIN_DISTANCE = 2.0

-- Reverse these if the physical installation is mirrored.

local YAW_SIGN = 1.0
local PITCH_SIGN = 1.0

--------------------------------------------------
-- CLAMP
--------------------------------------------------

local function clamp(
    value,
    minimum,
    maximum
)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

--------------------------------------------------
-- RESET
--------------------------------------------------

local function reset()

    state.guidance.commandX = 0
    state.guidance.commandY = 0

    state.guidance.yawError = 0
    state.guidance.pitchError = 0
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    if not state.system.running then
        return
    end

    if not state.navigation.online then

        state.guidance.online = false

        state.guidance.status =
            "OFFLINE"

        reset()

        return
    end

    if not state.target.set then

        state.guidance.online = true

        state.guidance.status =
            "NO TARGET"

        reset()

        return
    end

    local bx =
        state.navigation.bodyX

    local by =
        state.navigation.bodyY

    local bz =
        state.navigation.bodyZ

    local horizontal =
        math.sqrt(
            bx * bx
            + bz * bz
        )

    local distance =
        math.sqrt(
            horizontal * horizontal
            + by * by
        )

    if distance <= MIN_DISTANCE then

        state.guidance.online = true

        state.guidance.status =
            "ON TARGET"

        reset()

        return
    end

    --------------------------------------------------
    -- ANGULAR ERRORS
    --------------------------------------------------

    local yawError =
        math.atan2(
            bx,
            bz
        )

    local pitchError =
        math.atan2(
            by,
            horizontal
        )

    --------------------------------------------------
    -- COMMANDS
    --------------------------------------------------

    local commandX =
        clamp(
            math.sin(yawError)
            * YAW_GAIN,

            -MAX_COMMAND,
            MAX_COMMAND
        )

    local commandY =
        clamp(
            math.sin(pitchError)
            * PITCH_GAIN,

            -MAX_COMMAND,
            MAX_COMMAND
        )

    state.guidance.yawError =
        yawError

    state.guidance.pitchError =
        pitchError

    state.guidance.commandX =
        commandX * YAW_SIGN

    state.guidance.commandY =
        commandY * PITCH_SIGN

    state.guidance.online = true

    state.guidance.status =
        state.system.controlEnabled
        and "ACTIVE"
        or "MONITOR"

    state.guidance.lastUpdate =
        os.clock()

    state.guidance.updateCount =
        state.guidance.updateCount + 1
end

--------------------------------------------------
-- INIT
--------------------------------------------------

function init()

    reset()

end

--------------------------------------------------
-- LOOP
--------------------------------------------------

function run()

    while state.system.running do

        update()

        sleep(0.05)

    end

    reset()

    state.guidance.online = false

    state.guidance.status =
        "OFFLINE"
end