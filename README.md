# Dead-Lined Codebase

Godot 4.7.2 project written in GDScript using the Forward+ renderer.

This README covers development setup, architecture, implementation contracts, validation, and repository structure. For gameplay rules, balance intent, theme, and player experience, see [GAMEDESIGNDOCUMENT.md](GAMEDESIGNDOCUMENT.md).

## Environment Setup

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

Enemies share `EnemyBase` for health, damage/death handling, spawn intro state, conveyor velocity, and common components. Turrets inherit the reusable [turret_base.tscn](scenes/world/entities/turret_base.tscn) template for health, repair, upgrades, phase lifecycle, interaction UI, collision, particles, animation, and damage/death handling. `TurretBase` also initializes the common health bar and `TurretHUD`, whose upgrade panel owns the shared upgrade workflow. The base owns all common node names as direct children, including `Visuals`; derived scenes must put their body artwork below `Visuals` so inherited reset, repair, hit, and death animations can address the whole visual tree. Seeker and Shockwaver retain only their behavior-specific components and visuals, while Seeker Strong inherits Seeker and overrides only its stats resource. Shared turret balancing fields live in `TurretStats`; concrete stats resources add behavior-specific values.

Turret hit feedback is part of the [turret_base.tscn](scenes/world/entities/turret_base.tscn) contract: `TurretBase` requires [shaders/hit_flash.gdshader](shaders/hit_flash.gdshader), installs it on the body visual and optional cannon, and reports an error if the shader is missing. It pulses the material uniform with a short tween instead of playing a damage animation, so taking damage never interrupts firing or shockwave telegraph animations.

Turret repair is hold-to-repair: while the player is inside `InteractionZone` and holds the `repair` action (Left Shift; separate from `interact`, which is left click for turret placement), `TurretBase._physics_process` calls `RepairComponent.try_repair()` each frame (draining capacity at `capacity_drain_rate`, healing at `health_restore_rate`) and requests the looping `repair` animation, which pulses `Visuals:modulate` green and emits `RepairParticles`. Repair stops when the key is released, the player leaves, health is full, or capacity cannot cover the next tick; `AnimationHandler.stop_animation("repair")` then restores `RESET`. `repair` is a locking animation at priority 3 and blocks turret behavior: starting repair calls the turret's `_on_combat_stopped()` hook (Seeker drops its telegraph, Shockwaver disables its pulse) and `is_turret_active()` returns false while repairing; releasing calls `_on_combat_started()` again if the combat phase is still active. Concrete turrets must therefore make both hooks safe to call mid-combat.

### Creating a new turret

Use [turret_base.tscn](scenes/world/entities/turret_base.tscn) as the starting template. The base scene already provides common health, repair, upgrade, HUD, interaction, exclusion, range, phase lifecycle, animation, hit particles, death effects, collision, and hit-flash shader setup.

1. Duplicate `turret_base.tscn` and save it as the new turret scene. Keep the common direct-child node names unchanged: `HealthComponent`, `HealthUIComponent`, `InteractionZone`, `TurretUpgradeComponent`, `RepairComponent`, `TurretExclusionZone`, `RangeIndicator`, `TurretHUD`, `AnimationHandler`, `FlashVfx`, `HitParticles`, `WindupParticles`, `RepairParticles`, and `Visuals`.
2. Replace or add the turret artwork below `Visuals`. Put the main body at `Visuals/Sprite2D` or `Visuals/AnimatedSprite2D`; put a rotating cannon at `Visuals/Canon` and its artwork at `Visuals/Canon/Graphics` when the turret has one. Do not move `Visuals`, because inherited animations target that node.
3. Assign the hit-flash shader through the base scene's `hit_flash_shader` property. `TurretBase` installs separate materials on the body and cannon visuals at runtime. A missing shader is a configuration error and reports with `push_error`.
4. Add a turret script extending `TurretBase`. Export a stats resource that extends `TurretStats`, call `initialize_base(...)`, initialize behavior components, and implement the turret's phase hooks (`_on_combat_started()` and `_on_combat_stopped()`) as needed.
5. Keep individual behavior in child components where practical. The turret script owns orchestration and wires those components together; components own their state and emit signals upward.
6. Override `get_damage_value()` and `apply_damage_upgrade(amount)` when the turret deals upgradeable damage. These methods are the shared upgrade-panel contract.
7. Add behavior-specific animations to the inherited `AnimationHandler` library. Configure them in the script with `animation.configure_animation(name, priority, locks)` and use node paths relative to `AnimationHandler`. Keep `RESET`, `repair`, and `die` from the base library unless the turret has a deliberate replacement. Damage feedback is shader-driven; the base no longer carries unused idle or take-damage animation clips. If a turret script overrides `_physics_process`, it must call `super._physics_process(delta)` because `TurretBase` runs hold-to-repair there.
8. Add the new turret to its stats/resource files, shop entry, ghost scene, and `ShopManager` entries only after the standalone scene works. Verify placement preview range and exclusion radius are authored in the generic `TurretEntry` resource.
9. Validate the scene with the editor command, run the scene standalone, and manually verify: health changes on damage, body/cannon flash white, repair and upgrade UI, phase transitions, behavior animation timing, death effects, and placement/shop flow.

### Fail-fast guard policy

Do not use `is_inside_tree()` as a general error-suppression guard around normal calls. If a required node, resource, shader, animation, or component is missing, report it with `push_error` or an assertion so the configuration problem is visible immediately. Early returns are appropriate for expected gameplay state, such as cooldowns, disabled abilities, no target found, unaffordable actions, or a one-shot callback arriving after an object has already been invalidated.

The targeting system retains one explicit tree-membership check because it validates a cached target reference that can outlive or detach from the scene tree during enemy death. That is a stale-reference safety check, not a substitute for required initialization. The scrap despawn timer only checks `can_collect`; its lifecycle is controlled by the node and timer signal rather than silently ignoring a detached node.

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

Chaser, Stalker, and Seeker target priorities are authored only in their stats resources. Their scenes retain `TargetConfig` resources solely to declare target groups; orchestrators pass priorities and distance-switch thresholds into `TargetingComponent` at initialization. For enemies, a larger `priority_distance_threshold` strengthens player preference by requiring a lower-priority turret to be that much closer before taking focus. Seekers also configure same-priority hysteresis so nearby enemy movement does not make turrets continually abandon their current aim target.

### Known deliberate deviations from a "pure" component model

A few places intentionally cross the strict ownership boundary because the added indirection isn't worth it for a single-scene game:

- Turret repair drains player capacity directly (`repair.capacity_drained.connect(player.capacity.spend)`) rather than going through an event/coordinator layer.
- Spawners and factories (`ShootComponent`, `EnemySpawner`, `TurretPlacer`) call `get_tree().current_scene.add_child(...)` directly instead of routing through a dedicated spawn coordinator.
- `DropScrapComponent.drop()` looks up the player via `get_tree().get_first_node_in_group("player")` and reads `player.crunch_time.is_crunch_time_active()` directly to skip scrap drops during crunch time, instead of the player broadcasting a "no drops" event enemies subscribe to.

These are acceptable trade-offs, not bugs — revisit only if the game grows multiple scenes or needs pooling/threading.

### Enemy spawn intro

`EnemySpawner` instances can sit outside the playable area and expose `spawn_intro_direction` plus `spawn_intro_distance`. A spawned `EnemyBase` is initially non-colliding, invulnerable, AI-disabled, and visually held on the first idle frame while its root is tweened from the spawner position to the release position. Sleep/wake visuals are editable `spawn_sleep` and `spawn_wake` animations on each enemy scene: sleep tints the body grey, and wake fades it back to normal. On arrival, `EnemyBase` restores collision, contact damage, animation, and normal physics processing, then plays `spawn_wake`. The tween duration is derived as `spawn_intro_distance / ConveyorSettings.enemy_movement_speed`, so its world-space speed matches enemy conveyor movement exactly. This is presentation owned by the spawner and shared enemy base; individual enemy AI scripts do not contain spawn-entry behavior.

Conveyor belts are inline `Area2D` components in the level scene, not standalone scenes. Each uses [scripts/world/spawners/conveyor_belt.gd](scripts/world/spawners/conveyor_belt.gd), detects PlayerBody and EnemyBody layers, and owns a child `CollisionShape2D` whose dimensions are currently authored in the level scene. Both the belt and spawner reference [resources/spawner/conveyor_settings.tres](resources/spawner/conveyor_settings.tres), the single source of truth for `enemy_movement_speed` and `player_movement_speed`. The belt talks to bodies only through `set_conveyor_velocity()` / `clear_conveyor_velocity()`; while overlapping, the matching conveyor velocity is added to normal player/enemy movement so they can steer off the belt. The spawn tween remains responsible for crossing the outer wall while collision is disabled.

### Wave System

Build-phase duration is configured in [resources/wave_settings.tres](resources/wave_settings.tres) as `build_phase_duration`.

Each `EnemySpawner` builds a finite shuffled queue from [resources/spawner/enemy_spawn_stats.tres](resources/spawner/enemy_spawn_stats.tres) and spawns it at the configured interval. Each enemy entry owns its enabled state, introduction wave, base amount, multiplicative per-wave amount growth, and cumulative health multiplier interval. Counts are per spawner.

Combat ends only after every spawner finishes its queue and all spawned enemies are dead (not on a timer—victory requires clearing enemies). Pickups remain during build phase and are cleared when the next combat phase begins.

### Type-safety standard

This project uses strict GDScript typing for signal callbacks and loops. Any anonymous function passed to `connect()` must either declare its parameter type(s) or include an explicit `-> void` return type. Any `for` loop variable that is not inference-safe should be explicitly typed, e.g. `for rider: Node in _riders.values():` and `for config: TargetConfig in _sorted_configs:`. If a value can be ambiguous, declare its type explicitly (`var intro_speed: float = ...`). This is not style-only; it keeps Godot diagnostics clean and prevents silent type drift.

### Crunch-time visual effects system

Crunch-time presentation is split between [scripts/data/crunch_time_effects.gd](scripts/data/crunch_time_effects.gd) / [resources/crunch_time_effects.tres](resources/crunch_time_effects.tres) and the HUD's editable AnimationPlayer clips in [scenes/ui/hud.tscn](scenes/ui/hud.tscn). The HUD scene owns editor-facing presentation details such as the ready label text and layout. The resource owns state-dependent tuning such as overlay intensity, active camera zoom, and sprite tint. `CrunchTimeComponent` owns the fixed-duration lifecycle and camera transition through a camera reference injected by `Player`; it captures the camera's current zoom on activation and restores that value when crunch time ends. `Player` spends the configured capacity cost once when activation is signaled, then coordinates gameplay buffs and sprite tint until the component ends the mode. Cost and duration are authored in [resources/player_stats.tres](resources/player_stats.tres). The HUD AnimationPlayer owns the capacity bar's `capacity_ready`, `capacity_active`, and `capacity_change` motion; the ready label's size pulse is a track inside `capacity_ready`. These clips use integer-pixel vertical movement and no scale/rotation on the pixel-art bar, so timing and keyframes can be adjusted directly in the scene editor without subpixel distortion.

### Primary Attack Routing

`Player` routes the primary attack action to `ShootComponent` normally and `MeleeWeapon` during Crunch Time. `MeleeWeapon` handles enemy bodies through `HitboxComponent` and projectile areas through the generic `receive_wrench_hit()` contract. Turret repair support remains implemented behind that contract, but the current wrench collision mask excludes turret bodies.

### Shockwaver Prototype

[scenes/world/entities/shockwaver.tscn](scenes/world/entities/shockwaver.tscn) is registered through [resources/shop/shockwaver_shop_details.tres](resources/shop/shockwaver_shop_details.tres), alongside Seeker and Seeker Strong. `ShockwaveComponent` owns contact detection, windup, expanding annulus rendering, one-hit-per-target tracking, multi-target damage, and cooldown. The expanding ring uses [shaders/shockwave_pixel_art.gdshader](shaders/shockwave_pixel_art.gdshader), which generates a symmetric hard-edged ring from quantized fragment coordinates on a dedicated square canvas. Tune `ShockwaveComponent.shockwave_color`, `ShockwaveComponent.pixel_size`, and `ShockwaveComponent.center_line_thickness` in the scene Inspector; these control the ring color, pixel block size, and width of the white centerline in pixel-grid cells. The default centerline thickness is one pixel. The broad-phase `Area2D` detects player/enemy bodies; radial swept-ring math determines when the moving doughnut reaches each target without scaling collision shapes. `TurretEntry` owns generic shop preview range and exclusion-radius values so placement previews do not depend on a turret-specific stats schema.

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
