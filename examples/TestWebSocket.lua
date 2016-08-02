package.path = "./src/?.lua;./libs/?.lua;"

local TcpService = require "TcpService"
local AcyncConnect = require "Connect"
local WebSocket = require "WebSocket"

function userMain()
	local clientService = TcpService:New()
    clientService:createService()
	local ws = WebSocket:New()
	ws:setSession(clientService:connect("127.0.0.1", 8080, 10000, false))
	print(ws:connectHandshake("/ws"))
	ws:sendText("hello world")
	print(ws:readFrame())
end

coroutine_start(function ()
    userMain()
end)

while true
do
    CoreDD:loop()
    while coroutine_pengdingnum() > 0
    do
        coroutine_schedule()
    end
end