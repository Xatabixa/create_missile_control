-- Rocket module execution test
-- Does not modify the main missile control programs.

local state = require("state")

state.system.running = true

term.clear()
term.setCursorPos(1, 1)

print("ROCKET MODULE TEST")
print("==================")
print("")

--------------------------------------------------
-- LOAD MODULES
--------------------------------------------------

local modules = {
    navigation = "navigation.lua",
    actuator = "actuator.lua"
}

local loaded = {}

for name, path in pairs(modules) do

    local chunk, err =
        loadfile(path)

    if not chunk then

        print(
            name ..
            " LOAD FAILED"
        )

        print(
            tostring(err)
        )

    else

        loaded[name] = chunk

        print(
            name ..
            " LOAD OK"
        )

    end

end

print("")
print("Starting modules...")
print("")

--------------------------------------------------
-- RUN MODULES
--------------------------------------------------

parallel.waitForAny(

    function()

        if loaded.navigation then
            loaded.navigation()
        end

    end,

    function()

        if loaded.actuator then
            loaded.actuator()
        end

    end,

    function()

        sleep(2)

        print("")
        print("------------------")
        print("STATE AFTER 2 SEC")
        print("------------------")

        print(
            "Navigation: " ..
            tostring(
                state.navigation.online
            )
        )

        print(
            "Nav status: " ..
            tostring(
                state.navigation.status
            )
        )

        print(
            "Thruster: " ..
            tostring(
                state.thruster.online
            )
        )

        print(
            "Thruster status: " ..
            tostring(
                state.thruster.status
            )
        )

        print("")
        print("Updates:")

        print(
            "Navigation = " ..
            tostring(
                state.navigation.updateCount
            )
        )

        print(
            "Thruster = " ..
            tostring(
                state.thruster.updateCount
            )
        )

        print("")
        print("Press Q to stop.")

        while state.system.running do

            local _, key =
                os.pullEvent("key")

            if key == keys.q then

                state.system.running = false

            end

        end

    end

)

state.system.running = false

print("")
print("TEST FINISHED")