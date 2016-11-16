require "Scheduler"

local LinkQue  = require "linkque"
local lock = {}

function lock:new()
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  o.block = LinkQue.New()
  o.flag  = false
  o.owner = nil
  return o
end

function lock:Lock()
    local coObject = coroutine_running()
    assert(self.owner ~= coObject)
    
    if self.flag then
        self.block:Push(coObject)
        
        while self.flag do
            coroutine_sleep(coObject)
        end
    end
    
	self.flag = true
    self.owner = coObject
end

function lock:Unlock()
    assert(self.flag == true)
    assert(self.owner == coroutine_running())
    
	self.flag = false
    self.owner = nil
    
	local coObject = self.block:Pop()
	if coObject then
		coroutine_wakeup(coObject)
	end
end

return {
	New = function () return lock:new() end
}
