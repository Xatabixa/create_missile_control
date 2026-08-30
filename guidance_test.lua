-- guidance_test.lua
-- Test for the real guidance.lua
-- All system files are located in the computer root.

print("================================")
print("       GUIDANCE SYSTEM TEST")
print("================================")
print("")

-- Check files
if not fs.exists("state.lua") then
    print("ERROR: state.lua not found")
    return
end

if not fs.exists("guidance.lua") then
    print("ERROR: guidance.lua not found")
    return
end

print("state.lua: FOUND")
print("guidance.lua: FOUND")
print("")

-- Load state.lua
local stateFile = fs.open("state.lua", "r")

if stateFile == nil then
    print("ERROR: cannot open state.lua")
    return
end

local stateCode = stateFile.readAll()
stateFile.close()

local stateChunk, stateError = load(stateCode)

if stateChunk == nil then
    print("ERROR loading state.lua:")
    print(stateError)
    return
end

local state = stateChunk()

print("state.lua: LOADED")
print("")

-- Create a simple require replacement
local oldRequire = require

require = function(name)

    if name == "state" then
        return state
    end

    print("Unknown module: " .. tostring(name))
    return nil
end

-- Load guidance.lua
local guidanceFile = fs.open("guidance.lua", "r")

if guidanceFile == nil then
    print("ERROR: cannot open guidance.lua")
    require = oldRequire
    return
end

local guidanceCode = guidanceFile.readAll()
guidanceFile.close()

local guidanceChunk, guidanceError = load(guidanceCode)

if guidanceChunk == nil then
    print("ERROR loading guidance.lua:")
    print(guidanceError)
    require = oldRequire
    return
end

local guidance = guidanceChunk()

require = oldRequire

if guidance == nil then
    print("ERROR: guidance.lua returned nil")
    return
end

print("guidance.lua: LOADED")
print("")

print("================================")
print("          FILE TEST OK")
print("================================")
print("")

print("The real guidance.lua was loaded.")
print("The real state.lua was loaded.")
print("")

print("Available guidance functions:")

if guidance.run then
    print("run: YES")
else
    print("run: NO")
end

if guidance.update then
    print("update: YES")
else
    print("update: NO")
end

if guidance.stop then
    print("stop: YES")
else
    print("stop: NO")
end

print("")
print("================================")
print("       TEST FINISHED")
print("================================")
