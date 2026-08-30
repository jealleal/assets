local cg = game:GetService("CoreGui")
local hs = game:GetService("HttpService")
local is = game:GetService("InsertService")
local ps = game:GetService("Players")
local sg = game:GetService("StarterGui")
local _executor_thread = coroutine.running()
local _currentIdentity = 3

local function _getLuaState()
    local t = coroutine.running()
    if t == nil then return nil end
    return tostring(t):match("0x(%x+)")
end

local Quasar = Instance.new("Folder", cg)
Quasar.Name = "Quasar"
local Pointer = Instance.new("Folder", Quasar)
Pointer.Name = "Pointer"
local Bridge = Instance.new("Folder", Quasar)
Bridge.Name = "Bridge"

local plr = ps.LocalPlayer
local rtypeof = typeof

local BridgeUrl = "http://localhost:9611"
local ProcessID = "%-PROCESS-ID-%"
local Vernushwd = "QUASAR-HWID-" .. plr.UserId

local notifsSuppressed = false

local function QuasarNotify(title, text, icon, duration, notifType)
    if notifsSuppressed then return end

    if notifType == "error" or notifType == "warn" then
        local cb = Instance.new("BindableFunction")
        cb.OnInvoke = function(response)
            if response == "Mute Alerts" then
                notifsSuppressed = true
            end
        end

        sg:SetCore("SendNotification", {
            Title = "Quasar Injector",
            Text = text or "",
            Icon = icon or "rbxassetid://93335241502475",
            Duration = duration or 5,
            Button1 = "Mute Alerts",
            Callback = cb,
        })
    else
        sg:SetCore("SendNotification", {
            Title = "Quasar Injector",
            Text = text or "",
            Icon = icon or "rbxassetid://93335241502475",
            Duration = duration or 5,
        })
    end
end

local resc = 3
local function bsend(dta, typ, set)
    local timeout = 5
    local clock = tick()

    if type(clock) ~= "number" or clock == nil then clock = 0 end
    dta = dta or ""
    typ = typ or "none"
    set = set or {}

    local requestCompleted = false
    local responseBody = ""
    local responseSuccess = false

    local success, request = pcall(function()
        return hs:RequestInternal({
            Url = BridgeUrl .. "/handle",
            Body = typ .. "\n" .. ProcessID .. "\n" .. hs:JSONEncode(set) .. "\n" .. dta,
            Method = "POST",
            Headers = { ["Content-Type"] = "text/plain" }
        })
    end)

    if not success or request == nil then return "" end

    local connection
    connection = request:Start(function(suc, response)
        responseSuccess = suc
        if suc and response then
            responseBody = response.Body or ""
        else
            responseBody = ""
        end
        requestCompleted = true
        if connection then connection:Disconnect() end
    end)

    local startTime = os.clock()
    while not requestCompleted do
        task.wait(0.1)
        if os.clock() - startTime > timeout then
            if connection then connection:Disconnect() end
            break
        end
    end

    if not responseSuccess then
        if resc == nil or type(resc) ~= "number" then resc = 3 end
        if resc <= 0 then
            QuasarNotify("Quasar", "Your files will no longer save!", nil, 7, "warn")
            return ""
        else
            resc = resc - 1
        end
    else
        resc = 3
    end

    return responseBody
end
-- Thread execution block
bsend("", "listen")
task.spawn(function()
    while true do
        local res = bsend("", "listen")
        if typeof(res) == "table" then RKO:Destroy() break end
        if res and #res > 1 then
            task.spawn(function()
                local func, funcerr = env.loadstring(res)
                if func then pcall(func) else warn(funcerr) end
            end)
        end
        task.wait()
    end
end)

print("init script loaded")
return {HideTemp = function() end, GetIs = function() end}
