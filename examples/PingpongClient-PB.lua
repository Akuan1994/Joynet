package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")
local TcpService = require "TcpService"
local AcyncConnect = require "Connect"

local totalRecvNum = 0

local protobuf = require "protobuf"

protobuf.register_file "loginGameServer.pb"

local function readPB(session)
    local lenPacket = session:receive(8)
    if lenPacket ~= nil then
        local len = string.unpack(">I4", lenPacket, 1)
        local op = string.unpack(">I4", lenPacket, 5)
        local pbData = session:receive(len-8)

        return len, op, pbData
    end
end

local function sendPB(session, op, pbData)
    session:send(string.pack(">I4", #pbData+8) .. string.pack(">I4", op) .. pbData)
end

function userMain()

    CoreDD:startLuaTimer(1000, function()
        print("delay 5000")
    end)
    
    --开启10个客户端
    local clientService = TcpService:New()
    clientService:createService()

    for i=1, 1 do
        coroutine_start(function ()
            local session = clientService:connect("127.0.0.1", 9999, 5000)

            if session ~= nil then
                local loginData = {
                    authentication = "e0323a9039add2978bf5b49550572c7c",
                }
                for j = 1, 100 do
                    sendPB(session, 1, protobuf.encode("agreement.loginGameServerMsg", loginData))
                end

                while true do
                local len, op, pbData = readPB(session)
                    if pbData ~= nil then
                        totalRecvNum = totalRecvNum + 1
                        if op ~= 1 then
                            error("op error")
                        end
                        sendPB(session, op, protobuf.encode("agreement.loginGameServerMsg", loginData))
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
