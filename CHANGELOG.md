# Changelog

## Unreleased
- Add Tab:Clear() for dynamic screens, including control-listener and key-capture cleanup.
- Suppress visibility shortcuts during keybind capture across library instances; Escape cancels capture.
- Queue notifications per window so messages do not overlap.
- Clean up global input listeners and pending UI tasks when the ScreenGui or root is destroyed externally.
- Fit windows into the safe viewport, clamp dragging/resizing, and account for UI scale during collapse.
- Snap slider defaults with the same rounding used by setters.
- Notify dropdown callbacks when Refresh clears a selection; pass `true` as its second argument for silent refresh.
- Format the library and examples, and add repeatable mocked contract tests.
- Roblox rendering and real-device verification remain pending.

## 1.0 — Development snapshot
- Extracted native UI into a standalone ModuleScript.
- Added independent instances, component handles and cleanup.
- Added repository documentation and examples.
- Runtime testing pending.
