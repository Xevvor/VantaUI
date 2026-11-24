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
Development snapshot with unreleased reliability fixes. The library and examples compile, and mocked input/lifecycle contract tests pass. Roblox rendering and real-device verification remain pending. Private repository; no public redistribution license is granted by this package.

## Local checks

With Python and a local [Luau CLI](https://github.com/luau-lang/luau) installed:

```text
python tests/run.py /path/to/luau
```

The tests simulate input, lifecycle, viewport calculations and notification timing; they do not render Roblox UI. Format Luau files with StyLua using the included `stylua.toml`.
