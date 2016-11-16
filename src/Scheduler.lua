local CoObject = require "Co"

local CO_STATUS_NONE = 1
local CO_STATUS_ACTIVED = 2 --激活
local CO_STATUS_SLEEP = 3   --睡眠状态
local CO_STATUS_YIELD = 4   --暂时释放控制权
local CO_STATUS_DEAD = 5    --销毁
local CO_STATUS_RUNNING = 6 --运行中

local scheduler =
{
    sleepTimer = {},
    nowRunning = nil,
    process = {},
    nextPid = 1
}

function scheduler:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

--强制唤醒
function scheduler:ForceWakeup(coObj)
    if coObj.status == CO_STATUS_SLEEP then
        self:CancelSleep(coObj)
        self:Add2Active(coObj)
    end
end

function scheduler:Running()
    return self.nowRunning
end

--添加到激活列表中
function scheduler:Add2Active(coObj)
    if coObj.status == CO_STATUS_NONE then
        coObj.status = CO_STATUS_ACTIVED
        self.process[self.nextPid] = coObj
        self.nextPid = self.nextPid + 1
    end
end

--取消sleep
function scheduler:CancelSleep(coObj)
    if coObj.status == CO_STATUS_SLEEP then
        if self.sleepTimer[coObj.sleepID] ~= nil then
            CoreDD:removeTimer(coObj.sleepID)
            self.sleepTimer[coObj.sleepID] = nil
        end
        
        coObj.status = CO_STATUS_NONE
    end
end

--睡眠ms
function scheduler:Sleep(coObj,ms)
    if coObj.status == CO_STATUS_RUNNING then
        if ms ~= nil then
            local id = CoreDD:startTimer(ms, "__scheduler_timer_callback")
            coObj.sleepID = id
            self.sleepTimer[id] = coObj
        end
        
        coObj.status = CO_STATUS_SLEEP
        coroutine.yield(coObj.co)
    end
end

--暂时释放执行权
function scheduler:Yield(coObj)
    if coObj.status == CO_STATUS_RUNNING then
        coObj.status = CO_STATUS_ACTIVED
        --继续放入激活队列
        self.process[self.nextPid] = coObj
        self.nextPid = self.nextPid + 1
        coroutine.yield(coObj.co)
    end
end

--主调度循环
function scheduler:Schedule()
    for _, v in pairs(self.process) do
        self.nowRunning = v
        v.status = CO_STATUS_RUNNING
        CoreDD:startMonitor()
        local r, e = coroutine.resume(v.co,v)
        self.nowRunning = nil
        
        if not r and e ~= nil then
            print("resume error :"..e)
        end
        
        if coroutine.status(v.co) == "dead" then
            v.status = CO_STATUS_DEAD
        end
    end
    
    --清空运行列表
    for k in pairs(self.process) do
        self.process[k] = nil
    end
    
    --重置下一个被调度的协程的Pid
    self.nextPid = 1
end

local sc = scheduler:new()

function __scheduler_timer_callback(id)
    local sleepCo = sc.sleepTimer[id]
    if sleepCo ~= nil then
        if sleepCo.status == CO_STATUS_SLEEP then
            sleepCo.status = CO_STATUS_NONE
            sc:Add2Active(sleepCo)
        end
    end
    sc.sleepTimer[id] = nil
end

function coroutine_start(func)
    local coObj = CoObject.New()
    coObj.status = CO_STATUS_NONE
    local co = coroutine.create(func)
    coObj:init(sc, co)
    sc:Add2Active(coObj)
    return coObj
end

--delay为nil,则为无限等待(睡眠)
function coroutine_sleep(coObj, delay)
    coObj.sc:Sleep(coObj, delay)
end

function coroutine_schedule()
    sc:Schedule()
end

function coroutine_yield(coObj)
    coObj.sc:Yield(coObj)
end

function coroutine_running()
    return sc:Running()
end

function coroutine_pengdingnum()
    return sc.nextPid - 1 --下一个被调度的协程的pid减1则为当前运行中的协程数量
end

function coroutine_wakeup(coObj)
    coObj.sc:ForceWakeup(coObj)
end