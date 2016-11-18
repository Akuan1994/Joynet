package.path = "./src/?.lua;./libs/?.lua;./libs/RPC/?.lua;"
require("Joynet")
local Service = require "RPCService"
local RPCCall = require "RPCCall"
local harbor = require "harbor"
local function userMain()
    --一个进程最多只能允许一个harbor
    --一个物理机允许多个进程,但各自的harbor监听不同的端口
    harbor.OpenHarbor(8888)
    
    coroutine_start(function()
    
        local server = Service:New()
        server:setName("echoServer")
        
        while true do
            local err, request = server:recvRequest()
            if request ~= nil then
                print("request data is "..request:getData())
                if request:isSync() then    --如果对方是同步call,则可以reply
                    request:reply("echo:"..request:getData())
                end
            end
        end
    end)
    
    coroutine_start(function()
        local client = Service:New()
        --同步阻塞RPC(等待返回值)
        local err, _response = client:SyncCall("127.0.0.1", 8888, "echoServer", "hello1")
        if err ~= nil then
            print(" err is :"..err)
        else
            print("response is ".._response.."\n")
        end
        
        RPCCall.AsyncRPCCall("127.0.0.1", 8888, "echoServer", "hello4")
        
        err, _response = client:SyncCall("127.0.0.1", 8888, "echoServer", "hello5")
        if err ~= nil then
            print(" err is :"..err)
        else
            print("response is ".._response.."\n")
        end
    end)
    
    coroutine_start(function()
        --非阻塞RPC
        RPCCall.AsyncRPCCall("127.0.0.1", 8888, "echoServer", "hello2")
        RPCCall.AsyncRPCCall("127.0.0.1", 8888, "echoServer", "hello3")
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