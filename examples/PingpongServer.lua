package.path = "./src/?.lua;./libs/?.lua;"

require("Joynet")

local TcpService = require "TcpService"
local AcyncConnect = require "Connect"

local totalRecvNum = 0
local totalClientNum = 0

function userMain()

    --开启服务器
    local serverService = TcpService:New()
    serverService:listen("0.0.0.0", 9999)

    coroutine_start(function()
        while true do
            local session = serverService:accept()
            if session ~= nil then
                totalClientNum = totalClientNum + 1
                coroutine_start(function ()
                    local strLen = 5        --读取5个字节
                    while true do
                        local packet = session:receive(strLen)
                        if packet ~= nil then
                            totalRecvNum = totalRecvNum + 1
                            session:send(packet)
                        end
                        if session:isClose() then
                            totalClientNum = totalClientNum - 1
                            break
                        end
                    end
                end)
            end
        end
    end)

    coroutine_start(function ()
            while true do
                coroutine_sleep(coroutine_running(), 1000)
                print("total recv :"..totalRecvNum.."/s"..", totalClientNum: "..totalClientNum)
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