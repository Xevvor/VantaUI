-- Small deterministic mock for lifecycle/input contracts. It does not render UI.
local Env = { now = 0, tasks = {}, instances = {}, warnings = {}, viewport = nil }
local vectorMT = {}
local function vector(x, y, z)
    return setmetatable({ X = x, Y = y, Z = z or 0 }, vectorMT)
end
vectorMT.__add = function(a, b)
    return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
vectorMT.__sub = function(a, b)
    return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
local Vector2 = { new = vector }
local Vector3 = { new = vector }
Env.viewport = vector(1280, 720)
local UDim = {
    new = function(scale, offset)
        return { Scale = scale, Offset = offset }
    end,
}
local dimMT = {}
local function dimensions(xs, xo, ys, yo)
    return setmetatable({ X = UDim.new(xs or 0, xo or 0), Y = UDim.new(ys or 0, yo or 0) }, dimMT)
end
dimMT.__add = function(a, b)
    return dimensions(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end
dimMT.__sub = function(a, b)
    return dimensions(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end
local UDim2 = {
    new = dimensions,
    fromOffset = function(x, y)
        return dimensions(0, x, 0, y)
    end,
    fromScale = function(x, y)
        return dimensions(x, 0, y, 0)
    end,
}
local Enum = setmetatable({}, {
    __index = function(t, kind)
        local enum = {}
        setmetatable(enum, {
            __index = function(e, name)
                local item = { Name = name, EnumType = enum, _type = "EnumItem" }
                rawset(e, name, item)
                return item
            end,
        })
        rawset(t, kind, enum)
        return enum
    end,
})
local function typeof(v)
    return type(v) == "table" and v._type or type(v)
end
local Color3 = {
    new = function(...)
        return { ... }
    end,
    fromRGB = function(...)
        return { ... }
    end,
}
local TweenInfo = {
    new = function(duration)
        return { Duration = duration }
    end,
}
local function signal()
    local event = { listeners = {} }
    function event:Connect(cb)
        local connection = { Connected = true, callback = cb }
        function connection:Disconnect()
            self.Connected = false
        end
        table.insert(self.listeners, connection)
        return connection
    end
    function event:Fire(...)
        for _, connection in ipairs(table.clone(self.listeners)) do
            if connection.Connected then
                connection.callback(...)
            end
        end
    end
    function event:DisconnectAll()
        for _, c in ipairs(self.listeners) do
            c:Disconnect()
        end
    end
    return event
end
local task = {}
function task.delay(seconds, cb)
    local handle = { At = Env.now + seconds, Callback = cb }
    table.insert(Env.tasks, handle)
    return handle
end
function task.defer(cb)
    return task.delay(0, cb)
end
function task.cancel(handle)
    handle.Cancelled = true
end
function Env.advance(seconds)
    local untilTime = Env.now + seconds
    local iterations = 0
    while true do
        local index, nextTask
        for i, handle in ipairs(Env.tasks) do
            if handle.At <= untilTime and (not nextTask or handle.At < nextTask.At) then
                index, nextTask = i, handle
            end
        end
        if not nextTask then
            break
        end
        table.remove(Env.tasks, index)
        Env.now = nextTask.At
        if not nextTask.Cancelled then
            nextTask.Callback()
        end
        iterations += 1
        assert(iterations < 10000, "Mock task loop did not settle")
    end
    Env.now = untilTime
end
local function warn(message)
    table.insert(Env.warnings, message)
end
local guiClasses =
    { Frame = true, ScrollingFrame = true, TextLabel = true, TextButton = true, TextBox = true, ImageLabel = true }
local methods = {}
local objectMT = {}
function methods:IsA(kind)
    return self._class == kind or kind == "GuiObject" and guiClasses[self._class] == true
end
function methods:GetChildren()
    return table.clone(self._children)
end
function methods:GetDescendants()
    local result = {}
    for _, child in ipairs(self._children) do
        table.insert(result, child)
        for _, descendant in ipairs(child:GetDescendants()) do
            table.insert(result, descendant)
        end
    end
    return result
end
function methods:FindFirstChild(name)
    for _, child in ipairs(self._children) do
        if child.Name == name then
            return child
        end
    end
end
function methods:WaitForChild(name)
    return assert(self:FindFirstChild(name), name)
end
function methods:FindFirstChildWhichIsA(kind)
    for _, child in ipairs(self._children) do
        if child:IsA(kind) then
            return child
        end
    end
end
methods.FindFirstChildOfClass = methods.FindFirstChildWhichIsA
function methods:GetPropertyChangedSignal(name)
    self._changed[name] = self._changed[name] or signal()
    return self._changed[name]
end
function methods:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self.Destroying:Fire()
    for _, child in ipairs(self:GetChildren()) do
        child:Destroy()
    end
    self.Parent = nil
    for _, event in pairs(self._events) do
        event:DisconnectAll()
    end
    for _, event in pairs(self._changed) do
        event:DisconnectAll()
    end
end
local eventNames = { Destroying = true, Activated = true, MouseEnter = true, MouseLeave = true, InputBegan = true }
objectMT.__index = function(o, key)
    if methods[key] then
        return methods[key]
    end
    if eventNames[key] then
        o._events[key] = o._events[key] or signal()
        return o._events[key]
    end
    if key == "AbsoluteSize" then
        if o._class == "ScreenGui" or o._class == "PlayerGui" then
            return Env.viewport
        end
        local parentSize = o.Parent and o.Parent.AbsoluteSize or Env.viewport
        local size = o.Size or dimensions()
        local scale = o:FindFirstChildOfClass("UIScale")
        scale = scale and scale.Scale or 1
        return vector(
            (parentSize.X * size.X.Scale + size.X.Offset) * scale,
            (parentSize.Y * size.Y.Scale + size.Y.Offset) * scale
        )
    end
    return o._props[key]
end
objectMT.__newindex = function(o, key, value)
    if key == "Parent" then
        local old = o._props.Parent
        if old then
            local index = table.find(old._children, o)
            if index then
                table.remove(old._children, index)
            end
        end
        o._props.Parent = value
        if value then
            table.insert(value._children, o)
        end
    else
        o._props[key] = value
    end
    if o._changed[key] then
        o._changed[key]:Fire()
    end
end
local Instance = {
    new = function(kind)
        local o = setmetatable({
            _class = kind,
            _props = {
                Name = kind,
                Visible = true,
                Size = dimensions(),
                Position = dimensions(),
                AnchorPoint = vector(0, 0),
            },
            _children = {},
            _events = {},
            _changed = {},
        }, objectMT)
        table.insert(Env.instances, o)
        return o
    end,
}
local player = Instance.new("Player")
local playerGui = Instance.new("PlayerGui")
playerGui.Parent = player
local UIS = {
    InputBegan = signal(),
    InputChanged = signal(),
    InputEnded = signal(),
    GetFocusedTextBox = function()
        return nil
    end,
}
local TweenService = {}
function TweenService:Create(object, info, props)
    local tween = { Completed = signal() }
    function tween:Play()
        for k, v in pairs(props) do
            object[k] = v
        end
        self.task = task.delay(info.Duration, function()
            self.Completed:Fire(Enum.PlaybackState.Completed)
        end)
    end
    function tween:Cancel()
        if self.task then
            task.cancel(self.task)
        end
        self.Completed:Fire(Enum.PlaybackState.Cancelled)
    end
    return tween
end
local game = {
    GetService = function(_, name)
        if name == "Players" then
            return { LocalPlayer = player }
        end
        if name == "UserInputService" then
            return UIS
        end
        if name == "TweenService" then
            return TweenService
        end
        error("Unexpected service: " .. name)
    end,
}
function Env.latestGui()
    local result
    for _, o in ipairs(Env.instances) do
        if o._class == "ScreenGui" and not o._destroyed then
            result = o
        end
    end
    return result
end
function Env.findText(parent, text)
    for _, o in ipairs(parent:GetDescendants()) do
        if o.Text == text then
            return o
        end
    end
end
function Env.globalListeners()
    local count = 0
    for _, event in ipairs({ UIS.InputBegan, UIS.InputChanged, UIS.InputEnded }) do
        for _, c in ipairs(event.listeners) do
            if c.Connected then
                count += 1
            end
        end
    end
    return count
end
function Env.resize(w, h)
    Env.viewport = vector(w, h)
    for _, o in ipairs(Env.instances) do
        if not o._destroyed and o.Name == "Viewport" then
            o:GetPropertyChangedSignal("AbsoluteSize"):Fire()
        end
    end
end
