-- это пизда или нормалды
local HttpService = game:GetService("HttpService")

_G.UI_PORT = 9003
_G.DexBackend = {
    Cache = {},
    InstanceMap = {},
    CurrentId = 0
}

local function sendToUI(payload)
    local json = HttpService:JSONEncode(payload)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        req({
            Url = "http://127.0.0.1:" .. tostring(_G.UI_PORT) .. "/",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    else
        game:HttpPost("http://127.0.0.1:" .. tostring(_G.UI_PORT) .. "/", json, "application/json")
    end
end

function _G.DexBackend.Register(inst)
    if not _G.DexBackend.Cache[inst] then
        _G.DexBackend.CurrentId = _G.DexBackend.CurrentId + 1
        local id = tostring(_G.DexBackend.CurrentId)
        _G.DexBackend.Cache[inst] = id
        _G.DexBackend.InstanceMap[id] = inst
        return id
    end
    return _G.DexBackend.Cache[inst]
end

function _G.DexBackend.GetInst(id)
    return _G.DexBackend.InstanceMap[tostring(id)]
end

function _G.DexBackend.FetchChildren(targetId)
    local target = targetId and _G.DexBackend.GetInst(targetId) or game
    if not target then return end

    local list = {}
    for _, child in ipairs(target:GetChildren()) do
        local id = _G.DexBackend.Register(child)
        table.insert(list, {
            Id = id,
            Name = child.Name,
            ClassName = child.ClassName,
            HasChildren = #child:GetChildren() > 0
        })
    end

    sendToUI({
        Type = "TreeUpdate",
        ParentId = targetId or "Root",
        Data = list
    })
end

function _G.DexBackend.FetchProps(targetId)
    local inst = _G.DexBackend.GetInst(targetId)
    if not inst then return end

    local props = {
        "Name", "Parent", "Archivable", "ClassName",
        "Transparency", "Reflectance", "Anchored", "CanCollide",
        "Position", "Size", "Color", "Material", "Velocity"
    }

    local values = {}
    for _, prop in ipairs(props) do
        pcall(function()
            local v = inst[prop]
            local t = typeof(v)
            if t == "Vector3" then
                values[prop] = {Type = "Vector3", Val = {X = v.X, Y = v.Y, Z = v.Z}}
            elseif t == "Color3" then
                values[prop] = {Type = "Color3", Val = {R = v.R, G = v.G, B = v.B}}
            elseif t == "Instance" then
                values[prop] = {Type = "Instance", Val = v.Name, TargetId = _G.DexBackend.Register(v)}
            elseif t == "EnumItem" then
                values[prop] = {Type = "EnumItem", Val = tostring(v)}
            else
                values[prop] = {Type = t, Val = v}
            end
        end)
    end

    sendToUI({
        Type = "PropsUpdate",
        InstanceId = targetId,
        Data = values
    })
end
