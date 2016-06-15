require "Co"

local CO_STATUS_NONE = 1
local CO_STATUS_ACTIVED = 2
local CO_STATUS_SLEEP = 3
local CO_STATUS_YIELD = 4
local CO_STATUS_DEAD = 5

scheduler =
{
    active_head = nil,--活动列表头
    active_tail = nil,--活动列表尾
    pending_add = {},--等待添加到活动列表中的coObject
    sleepTimer = {},
    nowRunning = nil
}

local sc = nil

function scheduler:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function scheduler:init()
end


function scheduler:ForceWakeup(coObj)
    if coObj.status == CO_STATUS_SLEEP then
        self:CancelSleep(coObj)
        self:Add2Active(coObj)
    end
end

function scheduler:Running()
    return self.nowRunning
end

--添加到活动列表中
function scheduler:Add2Active(coObj)
    if coObj.status == CO_STATUS_NONE then
        coObj.status = CO_STATUS_ACTIVED
        table.insert(self.pending_add,coObj)
    end
end

function scheduler:CancelSleep(coObj)
    if sc.sleepTimer[coObj.sleepID] ~= nil and coObj.status == CO_STATUS_SLEEP then
        CoreDD:removeTimer(coObj.sleepID)
        self.sleepTimer[coObj.sleepID] = nil
        coObj.status = CO_STATUS_NONE
    end
end


function __scheduler_timer_callback(id)
    if sc.sleepTimer[id] ~= nil then
        if sc.sleepTimer[id].status == CO_STATUS_SLEEP then
            sc.sleepTimer[id].status = CO_STATUS_NONE
            sc:Add2Active(sc.sleepTimer[id])
            sc.sleepTimer[id] = nil
        end
    end
end

--睡眠ms
function scheduler:Sleep(coObj,ms)
    --TODO::让lua tinker支持闭包function
    if coObj.status == CO_STATUS_ACTIVED and coObj == self.nowRunning then
        local id = CoreDD:startTimer(ms, "__scheduler_timer_callback")
        coObj.sleepID = id
        self.sleepTimer[id] = coObj
        coObj.status = CO_STATUS_SLEEP
        coroutine.yield(coObj.co)
    end
end

--暂时释放执行权
function scheduler:Yield(coObj)
    coObj.status = CO_STATUS_YIELD
    coroutine.yield(coObj.co)
end

--主调度循环
function scheduler:Schedule()

    --将pending_add中所有coObject添加到活动列表中
    for k,v in pairs(self.pending_add) do
            v.next_co = nil
            if self.active_tail ~= nil then
                self.active_tail.next_co = v
                self.active_tail = v
            else
                self.active_head = v
                self.active_tail = v
            end
    end
    
    self.pending_add = {}
    
    --运行所有可运行的coObject对象
    local cur = self.active_head
    local pre = nil

    while cur ~= nil do
        self.nowRunning = cur
        CoreDD:startMonitor()
        local r, e = coroutine.resume(cur.co,cur)

        if not r and e ~= nil then
            print("resume error:.."..e)
        end

        self.nowRunning = nil
        if coroutine.status(cur.co) == "dead" then
            cur.status = CO_STATUS_DEAD
        end

        local status = cur.status
        --当纤程处于以下状态时需要从可运行队列中移除
        if status == CO_STATUS_DEAD or status == CO_STATUS_SLEEP or status == CO_STATUS_YIELD then
            --删除首元素
            if cur == self.active_head then
                --同时也是尾元素
                if cur == self.active_tail then
                    self.active_head = nil
                    self.active_tail = nil
                else
                    self.active_head = cur.next_co
                end
            elseif cur == self.active_tail then
                    pre.next_co = nil
                    self.active_tail = pre
            else
                pre.next_co = cur.next_co
            end

            local tmp = cur
            cur = cur.next_co
            tmp.next_co = nil
            --如果仅仅是让出处理器，需要重新投入到可运行队列中
            if status == CO_STATUS_YIELD then
                self:Add2Active(tmp)
            end
        else
            pre = cur
            cur = cur.next_co
        end
    end
end

sc = scheduler:new()
sc:init()

function coroutine_start(func)
    local coObj = coObject:new()
    coObject.status = CO_STATUS_NONE
    local co = coroutine.create(func)
    coObj:init(nil, sc, co)
    sc:Add2Active(coObj)
    return coObj
end

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
    return #sc.pending_add
end

function coroutine_wakeup(coObj)
    coObj.sc:ForceWakeup(coObj)
end