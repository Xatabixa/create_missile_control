-- Missile Telemetry Logger
-- CC:Tweaked
--
-- Writes flight telemetry to:
--   flight_log.txt
--
-- This module does NOT control anything.
-- It only reads the shared state.
--
-- It is intended to run in parallel with:
--   navigation
--   guidance
--   actuator
--   target
--   flight
--   display
--
-- DATA LOGGED:
--   time
--   phase
--   position
--   altitude
--   speed
--   target distance
--   yaw error
--   pitch error
--   yaw rate
--   pitch rate
--   yaw command
--   pitch command
--   requested vector
--   applied vector
--   actual vector
--   power
--   thrust
--
-- FILE:
--   flight_log.txt
--
-- A new session header is appended every startup.
--
-- IMPORTANT:
-- No engine command is ever sent by this module.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local LOG_FILE =
    "flight_log.txt"


-- Normal standby logging.
local STANDBY_INTERVAL =
    0.50


-- Faster logging during flight.
local FLIGHT_INTERVAL =
    0.10


--------------------------------------------------
-- SAFE NUMBER
--------------------------------------------------

local function number(
    value
)

    value =
        tonumber(value)


    if not value then

        return "nan"

    end


    return string.format(
        "%.6f",
        value
    )

end


--------------------------------------------------
-- SAFE TEXT
--------------------------------------------------

local function text(
    value
)

    if value == nil then

        return "nil"

    end


    local result =
        tostring(value)


    result =
        result:gsub(
            "[%c%s]+",
            "_"
        )


    return result

end


--------------------------------------------------
-- OPEN LOG
--------------------------------------------------

local function openLog()

    local file =
        fs.open(
            LOG_FILE,
            "a"
        )


    if not file then

        return nil

    end


    return file

end


--------------------------------------------------
-- FLUSH
--------------------------------------------------

local function flush(
    file
)

    if not file then
        return
    end


    pcall(
        function()

            file.flush()

        end
    )

end


--------------------------------------------------
-- WRITE
--------------------------------------------------

local function writeLine(
    file,
    line
)

    if not file then
        return false
    end


    local ok =
        pcall(
            function()

                file.writeLine(
                    line
                )

                flush(
                    file
                )

            end
        )


    return ok

end


--------------------------------------------------
-- HEADER
--------------------------------------------------

local function writeHeader(
    file,
    state
)

    if not file then
        return
    end


    local target =
        state.target
        or
        {}


    local start =
        state.startPosition
        or
        {}


    writeLine(
        file,
        ""
    )


    writeLine(
        file,
        "========================================"
    )


    writeLine(
        file,
        "MISSILE TELEMETRY SESSION"
    )


    writeLine(
        file,
        "START_TIME=" ..
        number(
            os.clock()
        )
    )


    writeLine(
        file,
        "TARGET_X=" ..
        number(
            target.x
        )
    )


    writeLine(
        file,
        "TARGET_Y=" ..
        number(
            target.y
        )
    )


    writeLine(
        file,
        "TARGET_Z=" ..
        number(
            target.z
        )
    )


    writeLine(
        file,
        "TARGET_SET=" ..
        text(
            target.set
        )
    )


    writeLine(
        file,
        "START_X=" ..
        number(
            start.x
        )
    )


    writeLine(
        file,
        "START_Z=" ..
        number(
            start.z
        )
    )


    writeLine(
        file,
        "START_SET=" ..
        text(
            start.set
        )
    )


    writeLine(
        file,
        "FORMAT=CSV"
    )


    writeLine(
        file,
        "========================================"
    )


    writeLine(
        file,
        "TIME,PHASE,ACTIVE,CONTROL," ..
        "X,Y,Z,ALT,SPEED,DIST," ..
        "YAW_ERR,PITCH_ERR," ..
        "YAW_RATE,PITCH_RATE," ..
        "YAW_CMD,PITCH_CMD," ..
        "REQ_X,REQ_Y," ..
        "OUT_X,OUT_Y," ..
        "ACT_X,ACT_Y," ..
        "POWER,THRUST"
    )

end


--------------------------------------------------
-- GET CURRENT TELEMETRY
--------------------------------------------------

local function buildLine(
    state
)

    local navigation =
        state.navigation
        or
        {}


    local guidance =
        state.guidance
        or
        {}


    local thruster =
        state.thruster
        or
        {}


    local flight =
        state.flight
        or
        {}


    local position =
        navigation.position
        or
        {}


    --------------------------------------------------
    -- ACTIVE
    --------------------------------------------------

    local active =
        flight.active == true


    local control =
        state.system
        and
        state.system.controlEnabled == true


    --------------------------------------------------
    -- PHASE
    --------------------------------------------------

    local phase =
        flight.phase
        or
        guidance.flightPhase
        or
        "UNKNOWN"


    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local distance =
        navigation.targetDistance


    if distance == nil then

        distance =
            navigation.distance

    end


    if distance == nil then

        distance =
            guidance.distance

    end


    --------------------------------------------------
    -- TARGET ERRORS
    --------------------------------------------------

    local yawError =
        guidance.yawError
        or
        navigation.targetYaw
        or
        0


    local pitchError =
        guidance.pitchError
        or
        navigation.targetPitch
        or
        0


    --------------------------------------------------
    -- COMMANDS
    --------------------------------------------------

    local yawCommand =
        guidance.commandX
        or
        0


    local pitchCommand =
        guidance.commandY
        or
        0


    --------------------------------------------------
    -- REQUESTED VECTOR
    --------------------------------------------------

    local requestedX =
        thruster.requestedVectorX


    if requestedX == nil then

        requestedX =
            guidance.commandX

    end


    local requestedY =
        thruster.requestedVectorY


    if requestedY == nil then

        requestedY =
            guidance.commandY

    end


    --------------------------------------------------
    -- APPLIED VECTOR
    --------------------------------------------------

    local appliedX =
        thruster.appliedVectorX


    if appliedX == nil then

        appliedX =
            thruster.targetVectorX

    end


    local appliedY =
        thruster.appliedVectorY


    if appliedY == nil then

        appliedY =
            thruster.targetVectorY

    end


    --------------------------------------------------
    -- ACTUAL VECTOR
    --------------------------------------------------

    local actualX =
        thruster.vectorX


    local actualY =
        thruster.vectorY


    --------------------------------------------------
    -- POSITION
    --------------------------------------------------

    local x =
        position.x
        or
        0


    local y =
        position.y
        or
        navigation.altitude
        or
        0


    local z =
        position.z
        or
        0


    --------------------------------------------------
    -- LOG LINE
    --------------------------------------------------

    return table.concat(
        {

            number(
                flight.elapsed
                or
                0
            ),

            text(
                phase
            ),

            active
                and
                "1"
                or
                "0",

            control
                and
                "1"
                or
                "0",

            number(x),
            number(y),
            number(z),

            number(
                navigation.altitude
            ),

            number(
                navigation.speed
            ),

            number(
                distance
            ),

            number(
                yawError
            ),

            number(
                pitchError
            ),

            number(
                guidance.yawRate
                or
                navigation.angularRateY
            ),

            number(
                guidance.pitchRate
                or
                navigation.angularRateX
            ),

            number(
                yawCommand
            ),

            number(
                pitchCommand
            ),

            number(
                requestedX
            ),

            number(
                requestedY
            ),

            number(
                appliedX
            ),

            number(
                appliedY
            ),

            number(
                actualX
            ),

            number(
                actualY
            ),

            number(
                thruster.power
            ),

            number(
                thruster.thrust
            )

        },
        ","
    )

end


--------------------------------------------------
-- LOGGING LOOP
--------------------------------------------------

local function run(
    state
)

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    state.telemetry =
        state.telemetry
        or
        {}


    state.telemetry.online =
        false


    state.telemetry.status =
        "STARTING"


    state.telemetry.file =
        LOG_FILE


    state.telemetry.error =
        nil


    state.telemetry.samples =
        0


    state.telemetry.lastWrite =
        0


    --------------------------------------------------
    -- FILE
    --------------------------------------------------

    local file =
        openLog()


    if not file then

        state.telemetry.status =
            "FILE ERROR"


        state.telemetry.error =
            "Cannot open " ..
            LOG_FILE


        return

    end


    state.telemetry.online =
        true


    state.telemetry.status =
        "ONLINE"


    --------------------------------------------------
    -- SESSION HEADER
    --------------------------------------------------

    writeHeader(
        file,
        state
    )


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do

        local line =
            buildLine(
                state
            )


        if line then

            local ok =
                writeLine(
                    file,
                    line
                )


            if ok then

                state.telemetry.samples =
                    state.telemetry.samples +
                    1


                state.telemetry.lastWrite =
                    os.clock()


                state.telemetry.status =
                    "ONLINE"

            else

                state.telemetry.status =
                    "WRITE ERROR"


                state.telemetry.error =
                    "Cannot write " ..
                    LOG_FILE

            end

        end


        --------------------------------------------------
        -- Flight frequency
        --------------------------------------------------

        local interval =
            STANDBY_INTERVAL


        if state.flight
            and
            state.flight.active then

            interval =
                FLIGHT_INTERVAL

        end


        sleep(
            interval
        )

    end


    --------------------------------------------------
    -- FINAL ENTRY
    --------------------------------------------------

    local finalLine =
        buildLine(
            state
        )


    if finalLine then

        writeLine(
            file,
            finalLine
        )

    end


    --------------------------------------------------
    -- END SESSION
    --------------------------------------------------

    writeLine(
        file,
        "END_SESSION=" ..
        number(
            os.clock()
        )
    )


    writeLine(
        file,
        "SAMPLES=" ..
        tostring(
            state.telemetry.samples
            or
            0
        )
    )


    writeLine(
        file,
        "========================================"
    )


    pcall(
        function()

            file.close()

        end
    )


    state.telemetry.status =
        "OFFLINE"


    state.telemetry.online =
        false

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}