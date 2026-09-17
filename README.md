# Dead-Lined

A Godot 4.7 2D wave-defense game: survive enemy waves, place/upgrade turrets between waves, and use "Crunch Time" (a risky temporary buff) to push through combat.

Engine: **Godot 4.7.2**, GDScript only (no C#), Forward+ renderer.

---

## Environment setup (read this first, every session)

Godot is **not on a system-wide `godot` command** in this workspace. Use the full paths below.

```text
GUI editor (for the VS Code extension, manual play-testing):
C:\Users\markm\Desktop\dev\games\_TOOLS\godot-4.7.2\Godot_v4.7.2-stable_win64.exe

Console executable (for CLI/headless diagnostics — use this one for scripted checks):
C:\Users\markm\Desktop\dev\games\_TOOLS\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe
```

The `_TOOLS\godot-4.7.2` folder is also on the user PATH, but there is **no valid `godot.exe`** in it — always call the executables above by full path from PowerShell.

**Validate the project (no parser/resource errors, exits cleanly):**

```powershell
& 'C:\Users\markm\Desktop\dev\games\_TOOLS\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
```

Exit code `0` with no output means the project loads cleanly. This is the fastest regression check after any script/scene edit — run it after every change.

**Run the actual game headlessly** (useful for confirming it starts, not for full gameplay verification — the process keeps running, so stop it manually after a few seconds):

```powershell
& 'C:\Users\markm\Desktop\dev\games\_TOOLS\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path .
```

**Reproduce runtime errors (recommended):** launch via VS Code's `GDScript: Launch Project` debug configuration ([.vscode/launch.json](.vscode/launch.json)), play until the error occurs, and copy the exact error + stack trace from the Debug Console. That trace (file:line + call chain) is what actually diagnoses bugs — headless validation only catches load-time errors, not runtime logic errors triggered by gameplay/input.

The VS Code Godot Tools extension is already configured in [.vscode/settings.json](.vscode/settings.json) pointing at the GUI executable.

---

## Architecture

Four layers, signals flow **outward/upward**, direct calls flow **downward** to owned children only:

```text
UI          → reacts to signals, never mutates gameplay state directly
Systems     → WaveManager, ShopManager, ScoreManager, GameOverManager (scene-local, not autoloads)
World       → Player / enemies / turrets — orchestrator scripts composing components
Data        → Resource (.tres) subclasses — stats, never hold logic
```

Only one autoload exists: `MenuManager` ([scripts/systems/menu_manager.gd](scripts/systems/menu_manager.gd)). Everything else is scene-local under [scenes/game.tscn](scenes/game.tscn), because this is a single-session game — a global signal bus for everything would add indirection without benefit here.

### Component ownership

Each entity (Player, Chaser, Stalker, Turret, …) is an **orchestrator**: it composes child component nodes and wires their signals together in `_ready()` → `_connect_signals()`. Components:

- own their own state (health, capacity, cooldowns, …)
- expose it through methods (`spend()`, `take_damage()`, `initialize()`) and signals (`health_changed`, `capacity_changed`)
- never reach into siblings or the parent scene

Fallible actions return `bool` (`try_shoot()`, `try_slash()`, `try_dash()`) — the caller decides what happens on success (animation, sound, camera shake).

### Node references

| Pattern | Use for |
|---|---|
| `$Child` | Own child in the same packed scene |
| `%UniqueName` | Scene-wide unique node, same scene owner (e.g. `%WaveManager` from anywhere in `game.tscn`) |
| `@export` | Cross-scene reference assigned in the inspector |
| `get_tree().get_first_node_in_group(...)` | Singleton-style managers reached from a different owner (e.g. turrets finding `player`) |
| `get_tree().get_nodes_in_group(...)` | Collections (`"enemies"`, `"turrets"`) |

### Stats resources

Balancing values live in one `Resource` subclass per entity type ([scripts/data/](scripts/data/)), instantiated as `.tres` variants ([resources/](resources/)). Entities read from `@export var stats: XStats` in `_initialize()` and push values into components — components never hold the resource directly. Variants (e.g. `SeekerStrong`) are the same script with a different `.tres`, not a subclass.

### Known deliberate deviations from a "pure" component model

A few places intentionally cross the strict ownership boundary because the added indirection isn't worth it for a single-scene game:

- Turret repair drains player capacity directly (`repair.capacity_drained.connect(player.capacity.spend)`) rather than going through an event/coordinator layer.
- Spawners and factories (`ShootComponent`, `EnemySpawner`, `TurretPlacer`) call `get_tree().current_scene.add_child(...)` directly instead of routing through a dedicated spawn coordinator.
- `DropScrapComponent.drop()` looks up the player via `get_tree().get_first_node_in_group("player")` and reads `player.crunch_time.is_crunch_time_active()` directly to skip scrap drops during crunch time, instead of the player broadcasting a "no drops" event enemies subscribe to.

These are acceptable trade-offs, not bugs — revisit only if the game grows multiple scenes or needs pooling/threading.

### Enemy spawn intro

`EnemySpawner` instances can sit above the playable area and expose `spawn_intro_distance`. A spawned `EnemyBase` is initially non-colliding, invulnerable, AI-disabled, and visually held on the first idle frame while its root is tweened straight down from the spawner position to the release position. On arrival, `EnemyBase` restores collision, contact damage, animation, and normal physics processing. The tween duration is derived as `spawn_intro_distance / ConveyorSettings.movement_speed`, so its world-space speed matches the belt exactly. This is presentation owned by the spawner and shared enemy base; individual enemy AI scripts do not contain spawn-entry behavior.

`ConveyorBelt` ([scripts/world/spawners/conveyor_belt.gd](scripts/world/spawners/conveyor_belt.gd)) is a visual-free `Area2D` that detects only EnemyBody layer 4. Its exported `belt_size` updates a local `RectangleShape2D` in the editor. Both the belt and spawner reference [resources/spawner/conveyor_settings.tres](resources/spawner/conveyor_settings.tres), the single source of truth for `movement_speed`. The belt talks to enemies only through `set_conveyor_velocity()` / `clear_conveyor_velocity()`; while overlapping, the downward conveyor velocity is added to normal AI or knockback velocity so enemies can steer off the belt. The spawn tween remains responsible for crossing the outer wall while collision is disabled.

---

## Testing

No automated test framework is installed yet. Godot's community standard is **GUT (Godot Unit Test)**, run headlessly.

Worth unit-testing (pure logic, no input/physics/timing dependency):
`CapacityComponent`, `HealthComponent`, `RepairComponent`, `TargetingComponent`, wave-scaling math in `EnemySpawner`.

Not worth automating: movement feel, animation timing, camera shake, turret-placement UX — these need manual play-testing.

---

## Where things live

```text
scenes/game.tscn          main scene: Systems / World / UI subtrees
scripts/systems/          WaveManager, ShopManager, ScoreManager, GameOverManager, TurretPlacer
scripts/world/entities/   Player, enemies (Chaser/Stalker/Kamikazer), Turret, shared components
scripts/data/             Resource subclasses (stats)
resources/                .tres stat variants
scripts/ui/               HUD, shop panel, pause menu, turret panels
```
