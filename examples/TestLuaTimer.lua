package.path = "./src/?.lua;./libs/?.lua;"

require("Joynet")
require("Scheduler")

for i = 0, 1000 do
    CoreDD:startLuaTimer(1000, function()
        print("haha")
    end)
end

while true
do
    CoreDD:loop()
    coroutine_schedule()
end