-- guidance_test.lua
-- Real guidance.lua diagnostic test

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

local f = fs.open("state.lua", "r")

if not f then
    print("ERROR: cannot open state.lua")
    return
end

local stateCode = f.readAll()
f.close()

local stateChunk, stateError = load(stateCode)

if not stateChunk then
    print("ERROR loading state.lua")
    print(stateError)
    return
end

local state = stateChunk()

if not state then
    print("ERROR: state.lua returned nil")
    return
end

print("state.lua: LOADED")
print("")

-- Load guidance.lua source

local g = fs.open("guidance.lua", "r")

if not g then
    print("ERROR: cannot open guidance.lua")
    return
end

local guidanceCode = g.readAll()
g.close()

-- Replace the unsupported require("state")
local oldLine = 'local state = require("state")'
local newLine = 'local state = suppliedState'

if not string.find(guidanceCode, oldLine, 1, true) then
    print("ERROR: require line was not found")
    return
end

guidanceCode = string.gsub(
    guidanceCode,
    oldLine,
    newLine,
    1
)

print("require(): BYPASSED")
print("")

-- Make state available to guidance.lua
suppliedState = state

-- Compile modified guidance.lua

local guidanceChunk, guidanceError = load(guidanceCode)

if not guidanceChunk then
    print("ERROR loading guidance.lua:")
    print(guidanceError)
    return
end

-- Execute module

local guidance = guidanceChunk()

if not guidance then
    print("ERROR: guidance.lua returned nil")
    return
end

print("guidance.lua: LOADED")
print("")

-- Check exported functions

if guidance.run then
    print("run(): FOUND")
else
    print("run(): NOT FOUND")
end

print("")

-- Show current state

print("================================")
print("        CURRENT STATE")
print("================================")
print("")

print("Navigation online:")
print(state.navigation.online)

print("Navigation bearing:")
print(state.navigation.bearing)

print("Navigation elevation:")
print(state.navigation.elevation)

print("Navigation target:")
print(state.navigation.hasNavTarget)

print("")

print("Guidance online:")
print(state.guidance.online)

print("Guidance active:")
print(state.guidance.active)

print("Guidance status:")
print(state.guidance.status)

print("Command X:")
print(state.guidance.commandX)

print("Command Y:")
print(state.guidance.commandY)

print("")

print("================================")
print("          TEST PASSED")
print("================================")