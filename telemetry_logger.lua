-- Missile Telemetry Logger
-- CC:Tweaked
--
-- Compact flight log.
--
-- The log is overwritten on every startup.
--
-- Logged:
--   TIME
--   PHASE
--   ALT
--   SPEED
--   DIST
--   YAW_ERR
--   PITCH_ERR
--   YAW_RATE
--   PITCH_RATE
--   CMD_X
--   CMD_Y
--   OUT_X
--   OUT_Y
--
-- This module never controls engines.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local LOG_FILE =
    "flight_log.txt"

local STANDBY_INTERVAL =
    1.0

local FLIGHT_INTERVAL =
    0.20


--------------------------------------------------
-- NUMBER
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
        "%.4f",
        value
    )

end


--------------------------------------------------
-- TEXT
--------------------------------------------------

local function text(
    value
)

    if value == nil then
        return "nil"
    end

    return tostring(value)
        :gsub(
            "[%c%s,]+",
            "_"
        )

end


--------------------------------------------------
-- OPEN LOG
--
-- "w" intentionally overwrites the previous log.
--------------------------------------------------

local function openLog()

    local file =
        fs.open(
            LOG_FILE,
            "w"
        )

    if not file then
        return nil
    end

    return file

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

                pcall(
                    function()
                        file.flush()
                    end
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
        or {}


    local start =
        state.startPosition
        or {}


    writeLine(
        file,
        "MISSILE FLIGHT LOG"
    )


    writeLine(
        file,
        "TARGET=" ..
        number(target.x) ..
        "," ..
        number(target.y) ..
        "," ..
        number(target.z)
    )


    writeLine(
        file,
        "START=" ..
        number(start.x) ..
        "," ..
        number(start.z)
    )


    writeLine(
        file,
        "FORMAT=CSV"
    )


    writeLine(
        file,
        "TIME,PHASE,ALT,SPEED,DIST," ..
        "YAW_ERR,PITCH_ERR," ..
        "YAW_RATE,PITCH_RATE," ..
        "CMD_X,CMD_Y,OUT_X,OUT_Y"
    )

end


--------------------------------------------------
-- BUILD COMPACT LINE
--------------------------------------------------

local function buildLine(
    state
)

    local navigation =
        state.navigation
        or {}


    local guidance =
        state.guidance
        or {}


    local thruster =
        state.thruster
        or {}


    local flight =
        state.flight
        or {}


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
    -- PHASE
    --------------------------------------------------

    local phase =
        flight.phase
        or
        guidance.flightPhase
        or
        "UNKNOWN"


    --------------------------------------------------
    -- POSITION / ALTITUDE
    --------------------------------------------------

    local altitude =
        navigation.altitude


    if altitude == nil then

        altitude =
            navigation.position
            and
            navigation.position.y

    end


    --------------------------------------------------
    -- COMMAND
    --------------------------------------------------

    local commandX =
        guidance.commandX
        or
        0


    local commandY =
        guidance.commandY
        or
        0


    --------------------------------------------------
    -- APPLIED
    --------------------------------------------------

    local outX =
        thruster.appliedVectorX


    if outX == nil then

        outX =
            thruster.targetVectorX

    end


    local outY =
        thruster.appliedVectorY


    if outY == nil then

        outY =
            thruster.targetVectorY

    end


    --------------------------------------------------
    -- RATE
    --
    -- Use Guidance values first because Guidance
    -- contains the controller's currently selected
    -- rate channels.
    --------------------------------------------------

    local yawRate =
        guidance.yawRate


    if yawRate == nil then

        yawRate =
            navigation.angularRateZ

    end


    local pitchRate =
        guidance.pitchRate


    if pitchRate == nil then

        pitchRate =
            navigation.angularRateX

    end


    --------------------------------------------------
    -- LINE
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

            number(
                altitude
            ),

            number(
                navigation.speed
            ),

            number(
                distance
            ),

            number(
                guidance.yawError
                or
                0
            ),

            number(
                guidance.pitchError
                or
                0
            ),

            number(
                yawRate
            ),

            number(
                pitchRate
            ),

            number(
                commandX
            ),

            number(
                commandY
            ),

            number(
                outX
            ),

            number(
                outY
            )

        },
        ","
    )

end


--------------------------------------------------
-- RUN
--------------------------------------------------

local function run(
    state
)

    state.telemetry =
        state.telemetry
        or {}


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


    --------------------------------------------------
    -- OPEN
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
    -- HEADER
    --------------------------------------------------

    writeHeader(
        file,
        state
    )


    --------------------------------------------------
    -- LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do


        --------------------------------------------------
        -- BUILD
        --------------------------------------------------

        local line =
            buildLine(
                state
            )


        --------------------------------------------------
        -- WRITE
        --------------------------------------------------

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
        -- FREQUENCY
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
    -- FINAL LINE
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
    -- FOOTER
    --------------------------------------------------

    writeLine(
        file,
        "END"
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


    pcall(
        function()
            file.close()
        end
    )


    state.telemetry.online =
        false


    state.telemetry.status =
        "OFFLINE"

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}