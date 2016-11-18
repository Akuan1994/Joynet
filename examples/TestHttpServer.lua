package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")
local TcpService = require "TcpService"

local totalRecvNum = 0

function userMain()
    --开启http服务器
    local serverService = TcpService:New()
    serverService:listen("0.0.0.0", 80)
    coroutine_start(function()
        while true do
            local session = serverService:accept()
            if session ~= nil then
                coroutine_start(function ()

                    --读取报文头
                    local packet = session:receiveUntil("\r\n")

                    --读取多行头部
                    while true do
                        packet = session:receiveUntil("\r\n")
                        if packet ~= nil then
                            if #packet == 0 then
                                --print("recv empty line")
                                break
                            end
                        else
                            break
                        end
                    end

                    local htmlBody = "<html><head><title>This is title</title></head><body>hahaha</body></html>"
                    local response = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\nContent-Length: "..string.len(htmlBody).."\r\n\r\n"..htmlBody

                    session:send(response)
                    session:postShutdown()
                    totalRecvNum = totalRecvNum + 1
                end)
            end
        end
    end)

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