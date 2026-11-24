# VANTA UI

![VANTA logo](assets/logo.svg)

A standalone native Roblox client UI library. No external code dependencies or game-specific remotes.

## Installation
1. Create a ModuleScript named `VantaUI` in ReplicatedStorage and paste `VantaUI.lua` into it.
2. Create a LocalScript in StarterPlayerScripts and paste `examples/Basic.lua` into it.
3. Test in your own Roblox Studio place. The default visibility key is K; X hides and minus collapses the window.

```lua
local Vanta = require(game:GetService("ReplicatedStorage"):WaitForChild("VantaUI"))
local Window = Vanta:CreateWindow({Title = "My Project"})
local Tab = Window:Tab({Title = "Main"})
Tab:Button({Title = "Hello", Callback = function() print("Hello!") end})
```

## Documentation
- [API reference](docs/API.md)
- [Icons](docs/Icons.md)
- [Themes](docs/Themes.md)
- [Troubleshooting and test checklist](docs/Troubleshooting.md)
- [Full showcase](examples/Showcase.lua)
- [Changelog](CHANGELOG.md)

## Status
Version 1.0 development snapshot; runtime verification pending. Private repository; no public redistribution license is granted by this package.
