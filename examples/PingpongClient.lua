package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")
local TcpService = require "TcpService"
local AcyncConnect = require "Connect"

local totalRecvNum = 0

function userMain()
    CoreDD:startLuaTimer(1000, function()
        print("delay 5000")
    end)
    
    --开启10个客户端
    local clientService = TcpService:New()
    clientService:createService()
        
    for i=1,100 do
        coroutine_start(function ()
            local session = clientService:connect("127.0.0.1", 9999, 5000)
            if session ~= nil then
                local str = "hello"
                local strLen = string.len(str)
                
                for j = 0, 10 do
                    session:send(str)
                end
                
                while true do
                local packet = session:receive(strLen)
                    if packet ~= nil then
                        totalRecvNum = totalRecvNum + 1
                        session:send(packet)
                    end

                    if session:isClose() then
                        break
                    end
                end
            else
                print("connect failed")
            end
        end)
    end

    coroutine_start(function ()
            while true do
                coroutine_sleep(coroutine_running(), 1000)
                print("total recv :"..totalRecvNum.."/s")
                totalRecvNum = 0
            end
        end)
end

coroutine_start(function ()
    userMain()
end)

while true
do
    CoreDD:loop()
    coroutine_schedule()
end
