# API reference

All methods use Luau colon syntax. Options are tables. Callbacks are optional functions; errors are caught and logged. Initial values do not invoke callbacks.

## Library and window

```lua
local Vanta = require(game.ReplicatedStorage.VantaUI)
local Window = Vanta:CreateWindow({Title="Project", Author="Developer", Theme="Dark", Size=UDim2.fromOffset(760,540), ToggleKey=Enum.KeyCode.K, SideBarWidth=190})
```

| Option | Type | Default |
|---|---|---|
| Title | string | Untitled |
| Author | string | VANTA UI |
| Theme | string | Dark |
| Size | UDim2 | 760 × 540 pixels |
| ToggleKey | Enum.KeyCode | K |
| SideBarWidth | number | 190 |

One window per instance. For additional windows use `Vanta.new():CreateWindow(options)`. Destroyed instances cannot be reused. Prefer offset-based sizes for collapse behavior.

| Method | Behavior |
|---|---|
| SetTheme(name) | Dark or Light |
| SetToggleKey(key) | Enum.KeyCode or valid key name |
| SetVisible(boolean) | Show/hide |
| Toggle() | Reverse visibility |
| Collapse() | Toggle title-bar-only mode |
| Notify(options) | Show notification |
| OnDestroy(callback) | Register one cleanup callback (replaces previous) |
| Destroy() | Disconnect library global listeners and animate removal |

`Vanta:Notify(options)` and `Vanta:SetTheme(name)` target the default instance.

```lua
Window:Notify({Title="Notice", Content="Ready", Duration=3})
Window:OnDestroy(function() print("Clean up application tasks here") end)
```

Notification Title and Content are strings; Duration is optional seconds (3 by default).

## Navigation

```lua
local Group = Window:Section({Title="Overview"})
local Tab = Group:Tab({Title="Main", Icon="layout-dashboard"})
Tab:Select()
Tab:Section({Title="Controls"})
```

`Window:Tab(options)` creates a tab in a default General group. Titles are strings; Icon is optional. The first tab is selected automatically. Navigation groups are not collapsible.

## Components

All component titles are strings. Desc is an optional string (empty by default) where supported. Callback is optional. The following examples assume Tab is already created.

### Paragraph
```lua
local P = Tab:Paragraph({Title="Status", Desc="Ready"})
P:SetDesc("Updated")
```
Returns a handle with SetDesc(text).

### Button
```lua
local B = Tab:Button({Title="Run", Desc="Run an action", Callback=function() print("Run") end})
B:SetDesc("New description")
```
Callback receives no arguments. Returns SetDesc handle.

### Toggle
```lua
local T = Tab:Toggle({Title="Enabled", Value=false, Callback=function(value) print(value) end})
T:SetValue(true, true)
print(T:GetValue())
```
Value is boolean, default false. Methods: GetValue(), SetValue(value, silent), SetDesc(text). Silent=true suppresses callback.

### Slider
```lua
local S = Tab:Slider({Title="Amount", Step=5, Value={Min=0, Max=100, Default=25}, Callback=function(value) print(value) end})
S:SetValue(50, true)
```
Value table requires numeric Min and Max, Max > Min. Default defaults to Min and is clamped. Step defaults to 1 and must be positive. SetValue rounds relative to Min and clamps. Methods: GetValue(), SetValue(number, silent), SetDesc(text).

### Input
```lua
local I = Tab:Input({Title="Name", Placeholder="Enter name", Value="", Callback=function(text) print(text) end})
I:SetValue("Example")
```
Placeholder and Value default to empty strings. Callback fires on text changes, including programmatic changes. Methods: GetValue(), SetValue(value), SetDesc(text).

### Dropdown
```lua
local D = Tab:Dropdown({Title="Choice", Values={"A","B"}, Value="A", SearchBarEnabled=true, Callback=function(value) print(value) end})
D:Refresh({"C","D"})
D:Select("C")
```
Values is an array of strings (default empty); Value is optional initial selection; SearchBarEnabled defaults false. Methods: GetValue(), Select(value), SetValue(value), Refresh(values). Refresh clears selection without invoking callback. Select and SetValue invoke callback and do not validate membership. Single selection only; no Desc setter.

### Keybind
```lua
local K = Tab:Keybind({Title="Visibility key", Value="K", Callback=function(name) Window:SetToggleKey(name) end})
K:SetValue("L")
```
Value defaults to K. Callback receives key name when changed, not whenever the key is pressed. Methods: GetValue(), SetValue(keyName), SetDesc(text). SetValue invokes callback.

## Limitations
No multi-select, per-control icons, custom transparency, or persistence. Fixed-height controls may clip long descriptions. Resize is mouse-oriented. Runtime behavior has not yet been verified in Studio.
