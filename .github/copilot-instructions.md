# Copilot instructions for Dead-Lined

Read [README.md](../README.md) first — it has environment setup (Godot executable paths, validation commands) and the architecture summary.

## Keep README.md in sync

When a change affects architecture — new system, new component ownership pattern, new autoload, new cross-scene coupling, or a change to how signals/data flow — update the relevant section of `README.md` in the same turn as the code change. Do not leave it for a later pass.

## "Known deliberate deviations" section

`README.md` has a section listing intentional exceptions to the component-ownership model (e.g. direct capacity mutation, `current_scene.add_child` spawning).

- If you introduce a new exception to component ownership, loose coupling, or the signal-up/call-down rule, add one line to that list explaining what and why.
- If you fix/remove an existing deviation, delete its line.
- Treat the length of this list as a code-smell signal: prefer the non-deviating design first. Only add a deviation when the alternative (an event bus, a coordinator layer, an extra signal hop) adds more indirection than value for this single-scene game. Say so explicitly in the one-line justification.
- Periodically (when touching a related file), check whether an existing deviation can now be removed.

## Validating changes

Always run before considering a script/scene change done:

```powershell
& 'C:\Users\markm\Desktop\dev\games\_TOOLS\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
```

Exit code `0`, no output = clean. This does not catch runtime-only errors — those need a manual repro via the `GDScript: Launch Project` VS Code debug config.
