local LinkQue = require "linkque"
require "Scheduler"

local channel = {}

function channel:new()
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  o.chan = LinkQue.New()
  o.block = LinkQue.New()
  return o
end

function channel:Send(...)
	self.chan:Push({...})
	local coObject = self.block:Pop()  
	if coObject then
		coroutine_wakeup(coObject)
	end		
end

function channel:Recv()
	while true do
		local msg = self.chan:Pop()
		if not msg then
			local coObject = coroutine_running()
			self.block:Push(coObject)
			coroutine_sleep(coObject)
		else
			return table.unpack(msg)
		end
	end	
end

return {
	New = function () return channel:new() end
}