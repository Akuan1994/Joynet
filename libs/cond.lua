require "Scheduler"

local LinkQue  = require "linkque"
local cond = {}

function cond:new()
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  o.block = LinkQue.New()
  return o
end

function cond:wait()
    local coObject = coroutine_running()
    self.block:Push(coObject)
    coroutine_sleep(coObject)
end

function cond:notifyOne()    
	local coObject = self.block:Pop()
	if coObject then
		coroutine_wakeup(coObject)
	end
end

function cond:notifyAll()
    while not self.block:IsEmpty() do
        notifyOne()
    end
end

return {
	New = function () return cond:new() end
}