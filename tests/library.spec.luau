local Window = Vanta:CreateWindow({ Title = "First" })
local Gui = Env.latestGui()
local Screen = Gui:FindFirstChild("Viewport")
local Root = Screen:FindFirstChildWhichIsA("Frame")
local Tab = Window:Tab({ Title = "Controls" })
Env.advance(3.3)

local Slider = Tab:Slider({ Title = "Stepped", Step = 5, Value = { Min = 0, Max = 100, Default = 26 } })
assert(Slider:GetValue() == 25)
Slider:SetValue(26, true)
assert(Slider:GetValue() == 25)
print("PASS: slider defaults and setters use identical rounding")

local selected = "A"
local Dropdown = Tab:Dropdown({
    Title = "Choice",
    Values = { "A", "B" },
    Value = "A",
    Callback = function(v)
        selected = v
    end,
})
Dropdown:Refresh({ "B" })
assert(Dropdown:GetValue() == nil and selected == nil)
Dropdown:Select("B")
Dropdown:Refresh({ "C" }, true)
assert(Dropdown:GetValue() == nil and selected == "B")
print("PASS: dropdown refresh clears application state, with explicit silent mode")

local second = Vanta.new()
local OtherWindow = second:CreateWindow({ Title = "Second" })
local OtherGui = Env.latestGui()
local OtherRoot = OtherGui:FindFirstChild("Viewport"):FindFirstChildWhichIsA("Frame")
Env.advance(3.3)
local Key = Tab:Keybind({
    Title = "Key",
    Value = "K",
    Callback = function(v)
        Window:SetToggleKey(v)
    end,
})
local button = Env.findText(Gui, "K")
button.Activated:Fire()
assert(Key:GetValue() == "K", "Capturing should preserve the actual key value")
local firstVisible, secondVisible = Root.Visible, OtherRoot.Visible
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.K }, false)
assert(Root.Visible == firstVisible and OtherRoot.Visible == secondVisible)
Env.advance(0)
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.K }, false)
assert(Root.Visible ~= firstVisible and OtherRoot.Visible ~= secondVisible)
button.Activated:Fire()
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape }, false)
assert(Key:GetValue() == "K" and button.Text == "K")
Env.advance(0)
Window:SetVisible(true)
OtherWindow:SetVisible(true)
print("PASS: key capture suppresses shortcuts across windows and Escape cancels")

local beforeClear = Env.globalListeners()
local ClearTab = Window:Tab({ Title = "Dynamic controls" })
ClearTab:Slider({ Title = "Temporary slider", Value = { Min = 0, Max = 10, Default = 0 } })
ClearTab:Keybind({ Title = "Temporary key", Value = "L" })
Env.findText(Gui, "L").Activated:Fire()
ClearTab:Clear()
ClearTab:Clear()
assert(Env.globalListeners() == beforeClear)
assert(not Env.findText(Gui, "Temporary slider") and not Env.findText(Gui, "Temporary key"))
local shownBefore = Root.Visible
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.K }, false)
assert(Root.Visible ~= shownBefore, "Clearing a captured control must release capture")
Window:SetVisible(true)
print("PASS: clearing a tab removes controls, listeners, and key capture")

Window:Notify({ Title = "First notice", Content = "One", Duration = 0.1 })
Window:Notify({ Title = "Second notice", Content = "Two", Duration = 0.1 })
assert(Env.findText(Gui, "First notice") and not Env.findText(Gui, "Second notice"))
Env.advance(0.36)
assert(not Env.findText(Gui, "First notice") and Env.findText(Gui, "Second notice"))
Env.advance(0.36)
assert(not Env.findText(Gui, "Second notice"))
print("PASS: notifications display FIFO and never overlap")

Env.resize(480, 320)
local scale = Root:FindFirstChildOfClass("UIScale").Scale
assert(Root.Size.X.Offset * scale <= 456 and Root.Size.Y.Offset * scale <= 296)
local Top = Root:FindFirstChildWhichIsA("Frame")
Top.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = vector(0, 0) })
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = vector(99999, 99999) })
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
local halfWidth = Root.Size.X.Offset * scale / 2
local halfHeight = Root.Size.Y.Offset * scale / 2
assert(Root.Position.X.Offset + halfWidth <= 480 - 12 + 0.001)
assert(Root.Position.Y.Offset + halfHeight <= 320 - 12 + 0.001)
Window:Collapse()
Env.advance(0.4)
assert(Root.Size.Y.Offset == 54)
Window:Collapse()
Env.advance(0.4)
assert(Root.Size.Y.Offset * scale <= 296)
print("PASS: small viewport fitting, drag bounds, and scaled collapse/expand")

local destroyed = 0
Window:OnDestroy(function()
    destroyed += 1
end)
button.Activated:Fire()
Window:Notify({ Title = "Pending", Content = "Pending", Duration = 30 })
local before = Env.globalListeners()
Gui:Destroy()
assert(destroyed == 1 and Env.globalListeners() < before)
Window:Destroy()
assert(destroyed == 1)
Env.advance(35)
print("PASS: external ScreenGui destruction disconnects listeners, cancels work, and cleans up once")

local rootDestroyed = 0
OtherWindow:OnDestroy(function()
    rootDestroyed += 1
end)
OtherRoot:Destroy()
Env.advance(0)
assert(OtherGui.Parent == nil and rootDestroyed == 1 and Env.globalListeners() == 0)
print("PASS: external root destruction also disposes its ScreenGui and listeners")

local last = Vanta.new():CreateWindow({ Title = "Animated shutdown" })
local lastGui = Env.latestGui()
last:Destroy()
last:Destroy()
Env.advance(2)
assert(lastGui.Parent == nil and Env.globalListeners() == 0)
assert(#Env.warnings == 0)
print("PASS: explicit animated destruction remains idempotent")
