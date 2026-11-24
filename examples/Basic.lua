local Vanta = require(game:GetService("ReplicatedStorage"):WaitForChild("VantaUI"))
local Window = Vanta:CreateWindow({Title = "My Project"})
local Tab = Window:Tab({Title = "Main"})
Tab:Button({Title = "Hello", Callback = function() print("Hello!") end})
