package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")
local TcpService = require "TcpService"
local AcyncConnect = require "Connect"
local MYSQL = require "Mysql"
local Scheduler = require "Scheduler"
local joynet = JoynetCore()
local scheduler = Scheduler.New(joynet)

local totalQueryNum = 0

function userMain()
    local mysqlService = TcpService.New(joynet, scheduler)
    mysqlService:createService()
    local mysql = MYSQL:New()
    local isOK, err = mysql:connect(mysqlService, "192.168.2.200", 3306, 1000, "logindb", "trAdmin", "trmysql")
    for i=1, 8 do
        scheduler:Start(function ( ... )
            
            if not isOK then
                print("connect failed, err:"..err)
                return
            else
                print("connect success")
            end

            local res, err = mysql:query("update public.heros set name='asxs' where id = 1")
            if not res then
                print("query failed, err :"..err)
            end

            while true do
                local res, err = mysql:query("select playerId,name,sex,level,exp,silver from playerinfo where playerId = '33ceb07bf4eeb3da587e268d663aba1a'")
                if not res then
                    print("query failed, err :"..err)
                else
                    print("query result")
                    totalQueryNum = totalQueryNum + 1
                    for i,v in ipairs(res) do
                        print(string.format("data : %s\t%s",v.playerId, v.name))
                    end
                end
            end
        end)
    end

    scheduler:Start(function ()
        while true do
            scheduler:Sleep(scheduler:Running(), 1000)
            print("total query :"..totalQueryNum.."/s")
            totalQueryNum = 0
        end
    end)
end

scheduler:Start(function ()
    userMain()
end)

while true
do
    joynet:loop()
    scheduler:Scheduler()
end