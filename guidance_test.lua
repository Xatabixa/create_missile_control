-- guidance_test.lua
-- Real guidance.lua test
-- All files are in the computer root.

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

local stateCode = f.readAll()

f.close()

local stateChunk = load(stateCode)

if stateChunk == nil then
    print("ERROR: cannot load state.lua")
    return
end

local state = stateChunk()

print("state.lua: LOADED")
print("")

-- Read guidance.lua

local g = fs.open("guidance.lua", "r")

local guidanceCode = g.readAll()

g.close()

-- Remove the require line.
-- guidance.lua starts with:
-- local state = require("state")

local firstLineEnd = string.find(guidanceCode, "\n")

if firstLineEnd == nil then
    print("ERROR: invalid guidance.lua")
    return
end

local secondLineEnd = string.find(
    guidanceCode,
    "\n",
    firstLineEnd + 1
)

if secondLineEnd == nil then
    print("ERROR: invalid guidance.lua")
    return
end

local thirdLineEnd = string.find(
    guidanceCode,
    "\n",
    secondLineEnd + 1
)

if thirdLineEnd == nil then
    print("ERROR: invalid guidance.lua")
    return
end

local rest = string.sub(
    guidanceCode,
    thirdLineEnd + 1
)

local modifiedCode =
    "local state = suppliedState\n" ..
    rest

-- Create environment

local env = {}

setmetatable(env, {
    __index = _G
})

env.suppliedState = state

-- Load modified guidance

local guidanceChunk, err = load(
    modifiedCode,
    "guidance_test_guidance"
)

if guidanceChunk == nil then
    print("ERROR loading guidance.lua:")
    print(err)
    return
end

-- Try to set environment if supported

if setfenv then
    setfenv(guidanceChunk, env)
end

local guidance = guidanceChunk()

if guidance == nil then
    print("ERROR: guidance.lua returned nil")
    return
end

print("guidance.lua: LOADED")
print("")

if guidance.run then
    print("run(): FOUND")
else
    print("run(): NOT FOUND")
    return
end

print("")
print("================================")
print("       MODULE TEST PASSED")
print("================================")
print("")

print("Real guidance.lua successfully loaded.")
print("require() was bypassed.")
print("")

print("Guidance state:")

print("ONLINE:")
print(state.guidance.online)

print("STATUS:")
print(state.guidance.status)

print("ACTIVE:")
print(state.guidance.active)

print("COMMAND X:")
print(state.guidance.commandX)

print("COMMAND Y:")
print(state.guidance.commandY)

print("")
print("TEST COMPLETE")