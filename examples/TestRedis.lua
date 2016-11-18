package.path = "./src/?.lua;./libs/?.lua;"
require("Joynet")
local TcpService = require "TcpService"
local AcyncConnect = require "Connect"
local Redis = require "Redis"

local totalRecvNum = 0

function userMain()
	local redisService = TcpService:New()
	redisService:createService()

	coroutine_start(function ( ... )
		local redis = Redis:New()
		redis:connect(redisService, "192.168.12.128", 6979, 10000)
		redis:set("haha", "heihei")

		while true do
			local v, err = redis:get("haha")
			if v ~= nil then
				totalRecvNum = totalRecvNum + 1
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