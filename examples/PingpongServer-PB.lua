package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")
local TcpService = require "TcpService"
local AcyncConnect = require "Connect"

local totalRecvNum = 0
local totalClientNum = 0

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

local function packData(op, pbData)
    return string.pack(">I4", #pbData+8) .. string.pack(">I4", op) .. pbData
end

local function sendPB(session, op, pbData)
    session:send(string.pack(">I4", #pbData+8) .. string.pack(">I4", op) .. pbData)
end

function userMain()
    --开启服务器
    local serverService = TcpService:New()
    serverService:listen("0.0.0.0", 9999)

    coroutine_start(function()
        while true do
            local session = serverService:accept()
            if session ~= nil then
                totalClientNum = totalClientNum + 1
                local loginData = {
                    authentication = "e0323a9039add2978bf5b49550572c7c",
                }
                coroutine_start(function ()
                    while true do
                        local len, op, pbData = readPB(session)
                        if pbData ~= nil then
                            if op ~= 1 then
                                error("op error")
                            end
                            totalRecvNum = totalRecvNum + 1
                            sendPB(session, op, protobuf.encode("agreement.loginGameServerMsg", loginData))
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
