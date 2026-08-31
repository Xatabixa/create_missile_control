-- Guidance Diagnostic Mode
--
-- IMPORTANT:
-- This version DOES NOT control the engine.
-- It only calculates and displays navigation angles.
--
-- Test positions:
--   1. Target in front
--   2. Target behind
--   3. Target right
--   4. Target left
--
-- Use this to determine the actual coordinate
-- convention of the Navigation Table.

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local UPDATE_INTERVAL = 0.10


--------------------------------------------------
-- ANGLE NORMALIZATION
--------------------------------------------------

local function normalizeAngle(angle)

    angle =
        tonumber(angle) or 0


    while angle > math.pi do

        angle =
            angle - 2 * math.pi

    end


    while angle < -math.pi do

        angle =
            angle + 2 * math.pi

    end


    return angle
end


--------------------------------------------------
-- DEGREES
--------------------------------------------------

local function degrees(angle)

    return math.deg(
        tonumber(angle) or 0
    )

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    state.guidance =
        state.guidance or {}


    state.guidance.online =
        true


    state.guidance.status =
        "DIAGNOSTIC"


    state.guidance.active =
        false


    --------------------------------------------------
    -- VALUES
    --------------------------------------------------

    state.guidance.targetBearing =
        0


    state.guidance.currentHeading =
        0


    state.guidance.yawError =
        0


    state.guidance.rawTargetBearing =
        0


    state.guidance.rawHeading =
        0


    state.guidance.targetDX =
        0


    state.guidance.targetDY =
        0


    state.guidance.targetDZ =
        0


    state.guidance.commandX =
        0


    state.guidance.commandY =
        0


    --------------------------------------------------
    -- UPDATE
    --------------------------------------------------

    local function update()

        local navigation =
            state.navigation


        --------------------------------------------------
        -- NAVIGATION CHECK
        --------------------------------------------------

        if type(navigation) ~= "table" then

            state.guidance.status =
                "NAV OFFLINE"

            return

        end


        --------------------------------------------------
        -- TARGET CHECK
        --------------------------------------------------

        local target =
            state.target


        if type(target) ~= "table"
            or
            target.set ~= true then

            state.guidance.status =
                "NO TARGET"

            return

        end


        --------------------------------------------------
        -- TARGET VECTOR
        --------------------------------------------------

        local dx =
            tonumber(
                navigation.targetDeltaX
            )
            or 0


        local dy =
            tonumber(
                navigation.targetDeltaY
            )
            or 0


        local dz =
            tonumber(
                navigation.targetDeltaZ
            )
            or 0


        state.guidance.targetDX =
            dx


        state.guidance.targetDY =
            dy


        state.guidance.targetDZ =
            dz


        --------------------------------------------------
        -- HORIZONTAL DISTANCE
        --------------------------------------------------

        local horizontal =
            math.sqrt(
                dx * dx +
                dz * dz
            )


        --------------------------------------------------
        -- TARGET WORLD ANGLE
        --------------------------------------------------
        --
        -- Minecraft horizontal world angle:
        --
        -- +Z = 0°
        -- +X = +90°
        -- -Z = ±180°
        -- -X = -90°
        --
        --------------------------------------------------

        local targetAngle =
            0


        if horizontal >
            0.001 then

            targetAngle =
                math.atan(
                    dx,
                    dz
                )

        end


        --------------------------------------------------
        -- CURRENT HEADING
        --------------------------------------------------

        local heading =
            tonumber(
                navigation.heading
            )
            or 0


        --------------------------------------------------
        -- ERROR
        --------------------------------------------------

        local errorAngle =
            normalizeAngle(
                targetAngle -
                heading
            )


        --------------------------------------------------
        -- SAVE
        --------------------------------------------------

        state.guidance.rawTargetBearing =
            targetAngle


        state.guidance.rawHeading =
            heading


        state.guidance.targetBearing =
            targetAngle


        state.guidance.currentHeading =
            heading


        state.guidance.yawError =
            errorAngle


        --------------------------------------------------
        -- STATUS TEXT
        --------------------------------------------------

        state.guidance.status =
            "DIAGNOSTIC"


        state.guidance.active =
            true


        --------------------------------------------------
        -- DEBUG VALUES
        --------------------------------------------------

        state.guidance.targetAngleDeg =
            degrees(
                targetAngle
            )


        state.guidance.headingDeg =
            degrees(
                heading
            )


        state.guidance.yawErrorDeg =
            degrees(
                errorAngle
            )


        state.guidance.horizontalDistance =
            horizontal


        --------------------------------------------------
        -- COMMANDS LOCKED
        --------------------------------------------------

        state.guidance.commandX =
            0


        state.guidance.commandY =
            0

    end


    --------------------------------------------------
    -- LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do

        update()

        sleep(
            UPDATE_INTERVAL
        )

    end


    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

    state.guidance.commandX =
        0


    state.guidance.commandY =
        0


    state.guidance.active =
        false


    state.guidance.online =
        false


    state.guidance.status =
        "OFFLINE"

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}