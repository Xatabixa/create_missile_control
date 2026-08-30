local function updateGPS()

    -- GPS is optional.
    -- If it is unavailable, keep the manually
    -- entered starting position.

    if not gpsEnabled then

        state.navigation.gps = false

        if state.startPosition
            and state.startPosition.set then

            state.navigation.position.x =
                state.startPosition.x

            state.navigation.position.y =
                state.startPosition.y

            state.navigation.position.z =
                state.startPosition.z

            state.navigation.positionValid =
                true

        else
            state.navigation.positionValid =
                false
        end

        return
    end

    local now = os.clock()

    if now < gpsTick then
        return
    end

    gpsTick =
        now + 0.5

    local x, y, z =
        gps.locate(
            0.5,
            false
        )

    if x ~= nil then

        state.navigation.position.x =
            x

        state.navigation.position.y =
            y

        state.navigation.position.z =
            z

        state.navigation.positionValid =
            true

        state.navigation.gps =
            true

    else

        state.navigation.gps =
            false

        -- Keep the manually entered
        -- starting position if available.
        if state.startPosition
            and state.startPosition.set then

            state.navigation.position.x =
                state.startPosition.x

            state.navigation.position.y =
                state.startPosition.y

            state.navigation.position.z =
                state.startPosition.z

            state.navigation.positionValid =
                true
        else
            state.navigation.positionValid =
                false
        end
    end
end