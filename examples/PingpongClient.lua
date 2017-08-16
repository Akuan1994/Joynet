package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")

local TcpService = require "TcpService"
local AcyncConnect = require "Connect"
local Scheduler = require "Scheduler"
local joynet = JoynetCore()
local scheduler = Scheduler.New(joynet)

local totalRecvNum = 0

function userMain()
    --开启10个客户端
    local clientService = TcpService.New(joynet, scheduler)
    clientService:createService()
        
    for i=1,100 do
        scheduler:Start(function ()
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

    scheduler:Start(function ()
            while true do
                scheduler:Sleep(scheduler:Running(), 1000)
                print("total recv :"..totalRecvNum.."/s")
                totalRecvNum = 0
            end
        end)
end

scheduler:Start(function ()
    userMain()
end)

while true
do
    joynet:loop()
    scheduler:Schedule()
end
