-- LocalScript in StarterPlayerScripts; VantaUI ModuleScript in ReplicatedStorage.
local Vanta = require(game:GetService("ReplicatedStorage"):WaitForChild("VantaUI"))
local Window = Vanta:CreateWindow({
    Title = "Example Project",
    Author = "My Project",
    Theme = "Dark",
    Size = UDim2.fromOffset(760, 540),
    ToggleKey = Enum.KeyCode.K,
})
local Main = Window:Section({ Title = "Overview" })
local Tab = Main:Tab({ Title = "Dashboard", Icon = "layout-dashboard" })
local Status = Tab:Paragraph({ Title = "Status", Desc = "Ready" })
Tab:Button({
    Title = "Test notification",
    Callback = function()
        Window:Notify({ Title = "VANTA", Content = "Hello!", Duration = 3 })
    end,
})
Tab:Toggle({
    Title = "Example toggle",
    Value = false,
    Callback = function(v)
        Status:SetDesc(tostring(v))
    end,
})
Tab:Slider({
    Title = "Amount",
    Step = 5,
    Value = { Min = 0, Max = 100, Default = 25 },
    Callback = function(v)
        print(v)
    end,
})
Tab:Input({
    Title = "Name",
    Placeholder = "Type here",
    Callback = function(v)
        print(v)
    end,
})
Tab:Dropdown({
    Title = "Option",
    Values = { "One", "Two", "Three" },
    Value = "One",
    SearchBarEnabled = true,
    Callback = function(v)
        print(v)
    end,
})
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
Settings:Dropdown({
    Title = "Theme",
    Values = { "Dark", "Light" },
    Value = "Dark",
    Callback = function(v)
        Window:SetTheme(v)
    end,
})
Settings:Keybind({
    Title = "Hide key",
    Value = "K",
    Callback = function(v)
        Window:SetToggleKey(v)
    end,
})
Settings:Button({
    Title = "Unload",
    Callback = function()
        Window:Destroy()
    end,
})
