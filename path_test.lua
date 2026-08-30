term.clear()
term.setCursorPos(1, 1)

print("FILESYSTEM TEST")
print("================")
print("")

print("Current directory:")
print(shell.dir())

print("")

print("Running program:")
print(shell.getRunningProgram())

print("")

print("ROOT:")
for _, file in ipairs(fs.list("/")) do
    print(file)
end

print("")
print("ROCKET:")

if fs.exists("/rocket") then

    for _, file in ipairs(fs.list("/rocket")) do
        print(file)
    end

else

    print("ROCKET DIRECTORY NOT FOUND")

end

print("")
print("navigation.lua:")
print(
    tostring(
        fs.exists("/rocket/navigation.lua")
    )
)

print("")
print("Press any key...")

os.pullEvent("key")