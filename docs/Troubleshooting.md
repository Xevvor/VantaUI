# Troubleshooting

- Require the module from a LocalScript, not a server Script.
- Check the ModuleScript name and location if require fails.
- Wait for the intro animation; press K if the window is hidden.
- Inspect Studio Output for callback warnings prefixed `[VANTA]`.
- Use `Vanta.new()` for another window or after destroying an instance.
- Keep application-owned connections and tasks in your own cleanup callback.
- Use string arrays for dropdown options and valid Enum.KeyCode names for keybinds.

## Release checklist (not yet executed)
- Run Basic and Showcase in a private test place.
- Verify each control, setter, callback and dropdown refresh.
- Verify theme changes, hide/show, collapse, resize and drag.
- Verify independent windows and cleanup after destroy.
- Verify icon assets, small screens and touch behavior.
