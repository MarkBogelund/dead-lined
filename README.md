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
Systems     → WaveManager, ShopManager, ScoreManager, GameOverManager, TimeScaleManager (scene-local, not autoloads)
World       → Player / enemies / turrets — orchestrator scripts composing components
Data        → Resource (.tres) subclasses — stats, never hold logic
```

Only one autoload exists: `MenuManager` ([scripts/systems/menu_manager.gd](scripts/systems/menu_manager.gd)). Everything else is scene-local under [scenes/game.tscn](scenes/game.tscn), because this is a single-session game — a global signal bus for everything would add indirection without benefit here.

`TimeScaleManager` ([scripts/systems/time_scale_manager.gd](scripts/systems/time_scale_manager.gd)) is the only writer of `Engine.time_scale`. Callers `request(source, scale)` / `release(source)` by `StringName`; the slowest active request wins, and `freeze(duration)` is a timed request at 0. This lets hitstop and dash slow-motion overlap without one resetting the other. It resets time to 1.0 when it leaves the tree.

`GameCamera` ([scripts/world/game_camera.gd](scripts/world/game_camera.gd), on the player's `Camera2D` in `game.tscn`) owns zoom the same way: `set_zoom_factor(source, factor, duration, ignore_time_scale)` tweens a named factor that multiplies onto the base zoom (`&"crunch_time"` from `CrunchTimeComponent`, `&"dash_charge"` from `Player`), so the effects stack instead of overwriting each other. `SlowMotionOverlay` ([scripts/ui/slow_motion_overlay.gd](scripts/ui/slow_motion_overlay.gd), first child of `UI` so the HUD draws above it) listens to `player.dash.charge_started` / `charge_ended` and fades [shaders/slow_motion.gdshader](shaders/slow_motion.gdshader) (screen-texture desaturation) in and out on real time; it hides itself when faded out.

### Component ownership

Each entity (Player, Chaser, Stalker, Turret, …) is an **orchestrator**: it composes child component nodes and wires their signals together in `_ready()` → `_connect_signals()`. Components:

- own their own state (health, capacity, cooldowns, …)
- expose it through methods (`spend()`, `take_damage()`, `initialize()`) and signals (`health_changed`, `capacity_changed`)
- never reach into siblings or the parent scene

Fallible actions return `bool` (`try_shoot()`, `try_slash()`, `try_press()`) — the caller decides what happens on success (animation, sound, camera shake). Shooting is automatic: `Player._physics_process` calls `_process_auto_shoot()`, which keeps calling `try_shoot()` while the `shoot` action is held, so the fire rate is purely `ShootComponent.shoot_cooldown`. Auto-fire is armed only by a press reaching `Player._unhandled_input` and disarmed on release, so clicks consumed by UI or by `TurretPlacer` (which handles `interact` in `_input`) never start firing; shooting is also disabled for the duration of turret placement. The slash stays on press and takes over the same button during Crunch Time.

The player dash is charged: `DashComponent` runs `IDLE → HOLDING → CHARGING → DASHING → COOLDOWN`. `Player` calls `try_press()` on press and `release(direction)` on release or when `charge_maxed` fires. Releasing within `charge_delay` (HOLDING) is a plain `min_distance` dash with no slow-motion; past it the component enters CHARGING and emits `charge_started`. Both timers count real time (they divide out `Engine.time_scale`); `max_charge_time` is measured from the press. Distance is `lerp(min_distance, max_distance, charge_ratio)`; the dash starts at `dash_speed` and eases out, and `step_dash(delta)` integrates the exact displacement per physics step so the tuned distance is what the player travels. The component only emits `charge_started` / `charge_ended`; `Player` reacts by requesting/releasing `&"dash_charge"` on `TimeScaleManager` and playing `dash_charge` (slash frame 0, white `modulate` ramp, `WindupParticles`), speed-scaled so the ramp finishes at full charge; locomotion animations are skipped while charging. While charging, `DashDirectionIndicator` points a sprite (default `assets/sprites/player/dash_direction.png`, drawn pointing right) in the dash direction. It extends [PixelRotatedSprite](scripts/shared/pixel_rotated_sprite.gd), the shared node for sprites that must rotate without deforming: it draws its texture through [shaders/pixel_rotate.gdshader](shaders/pixel_rotate.gdshader), which nearest-samples on a whole-pixel grid, and it owns the fade in/out. The dash indicator adds `top_level` plus whole-pixel snapping to the player so the grid never shifts. The off-screen turret arrows use the same node. While the player is invincible (dash held or dashing, or Crunch Time), `Player._sync_body_layer()` removes it from the `PlayerBody` physics layer each physics frame, so enemy hitboxes and projectiles pass through instead of triggering (e.g. Kamikazer explosions); while dashing it also drops `TurretBody` from its collision mask, so it dashes through turrets just like it already passes through enemies. All values come from the `PlayerStats` Dash group.

Enemies share `EnemyBase` for health, damage/death handling, spawn intro state, conveyor velocity, and common components. Turrets inherit the reusable [turret_base.tscn](scenes/world/entities/turret_base.tscn) template for health, repair, upgrades, phase lifecycle, interaction UI, collision, particles, animation, and damage/death handling. `TurretBase` also initializes the common health bar and `TurretHUD`, whose upgrade panel owns the shared upgrade workflow. The base owns all common node names as direct children, including `Visuals`; derived scenes must put their body artwork below `Visuals` so inherited reset, repair, hit, and death animations can address the whole visual tree. Seeker and Shockwaver retain only their behavior-specific components and visuals, while Seeker Strong inherits Seeker and overrides only its stats resource. Stats resources are layered: shared fields at the top in a base class, type-specific fields in a subclass group below. `TurretStats` holds `max_health`, `damage`, `knockback`, `attack_range`, `attack_cooldown` (the same names `TurretUpgrade` uses), upgrades, selling, and repair; `SeekerStats`/`ShockwaverStats` add their own group. Enemies use `EnemyStats` (`max_health`, `damage`, `knockback`, `move_speed`, `targeting`, `orb_drop_amount`, `crunch_powerup_drop_chance`), extended by `ChaserStats`, `StalkerStats`, and `KamikazerStats`.

Enemy drops are orbs. [orb.gd](scripts/world/entities/shared/orb.gd) (`Orb`, a `RigidBody2D`) owns the shared pickup lifecycle: `launch(impulse)` starts its freeze and `lifetime` timers, `_connect_phase_signals()` / `_is_clearing_phase_active()` decide which phase clears uncollected orbs (a drop landing after that phase already started, as the wave's last enemy does mid-death-animation, despawns straight away), and collection calls two hooks, `_try_collect(player)` and `_on_collected(player)`. [orb.tscn](scenes/world/entities/orb.tscn) is the art-free base: collision, detection, particles and the shared `RESET`/`spin`/`pick_up`/`despawn` animations, which key the empty `Visuals` node's `scale` and `rotation` so any artwork put under it animates. Inherited scenes supply the look: [capacity_orb.tscn](scenes/world/entities/capacity_orb.tscn) ([CapacityOrb](scripts/world/entities/shared/capacity_orb.gd)) restores capacity and survives the build phase so leftovers can still be collected, clearing when the next combat phase starts; [crunch_powerup.tscn](scenes/world/entities/crunch_powerup.tscn) ([CrunchPowerup](scripts/world/entities/shared/crunch_powerup.gd)) carries the Crunch Time charge, clears as soon as combat ends, and reads [CrunchPowerupSettings](scripts/data/crunch_powerup_settings.gd) ([crunch_powerup_settings.tres](resources/player/crunch_powerup_settings.tres)) for its ground lifetime and trailing. `OrbDropComponent` on each enemy spawns `orb_drop_amount` capacity orbs from the `die` animation and rolls `crunch_powerup_drop_chance` for a powerup; nothing drops during Crunch Time.

Crunch Time is charge-based. `CrunchTimeComponent` owns a single charge: `Player.try_collect_crunch_powerup()` calls `add_charge()`, which refuses while Crunch Time is running or a charge is already carried, so the powerup stays on the ground. The collected powerup trails the player until `charge_spent` (the `crunch_time` action calls `try_activate()`, which spends the charge) or `charge_lost` (the player is hit or dies, or `set_build_phase(true)` at round end). The HUD's ready label and `capacity_ready` animation follow the same signals. Capacity no longer gates Crunch Time and has no threshold.

Turret surface effects are part of the [turret_base.tscn](scenes/world/entities/turret_base.tscn) contract: `TurretBase.surface_shader` is [shaders/turret_surface.gdshader](shaders/turret_surface.gdshader), which only composes three independent includes: [hit_flash.gdshaderinc](shaders/include/hit_flash.gdshaderinc) (`flash_*` uniforms, damage feedback), [gold_shine.gdshaderinc](shaders/include/gold_shine.gdshaderinc) (`gold_*`/`shine_*`/`sparkle_*` uniforms, max-level shine) and [damage.gdshaderinc](shaders/include/damage.gdshaderinc) (`damage_*`/`crack_*` uniforms, critical health). `TurretBase` installs one material per body/cannon visual and reports an error if the shader is missing; `_play_hit_flash()` touches only `flash_amount`, `_set_gold_shine()` touches only `gold_amount`, and `_set_critical()` touches only `damage_amount`. Add new sprite effects as another include plus one call in the composing shader. Hit feedback pulses the uniform with a short tween instead of playing a damage animation, so taking damage never interrupts firing or shockwave telegraph animations.

Critical turrets are flagged in two places. `TurretBase` listens to its own `HealthComponent.health_changed` and flips `_set_critical()` when health crosses `critical_health_ratio` (default 0.25), which recolours the sprite with a red tint pulsing between `tint_min` and `tint_max` while scorched pixels glitch in and out in place; selling clears it, and death hands the uniforms to `_play_death_burnout()`, which fades the red out while flashing the sprite white over `death_burnout_duration` so the effect lasts through the `die` animation. [CriticalTurretIndicators](scripts/ui/critical_turret_indicators.gd) (a full-rect `Control` in the `UI` layer of [game.tscn](scenes/game.tscn), above the HUD) caches the turret list when `ShopManager.turret_bought` fires and drops entries on `tree_exiting`, so it never scans the group per frame. Each frame it places a pulsing arrow `turret_offset` pixels from each critical turret, on the player's side of it and pointing back at the turret; the arrow only shows while the player is at least `min_player_distance` away, and fades out when the player closes in, on death, and on game over.

Turret repair is hold-to-repair: while the player is inside `InteractionZone` and holds the `repair` action (Left Shift; separate from `interact`, which is left click for turret placement), `TurretBase._physics_process` calls `RepairComponent.try_repair()` each frame (draining capacity at `repair_cost_per_second`, healing at `repair_health_per_second`) and requests the looping `repair` animation, which pulses `Visuals:modulate` green and emits `RepairParticles`. Repair stops when the key is released, the player leaves, health is full, or capacity cannot cover the next tick; `AnimationHandler.stop_animation("repair")` then restores `RESET`. `repair` is a locking animation at priority 3 and blocks turret behavior: starting repair calls the turret's `_on_combat_stopped()` hook (Seeker drops its telegraph, Shockwaver disables its pulse) and `is_turret_active()` returns false while repairing; releasing calls `_on_combat_started()` again if the combat phase is still active. Concrete turrets must therefore make both hooks safe to call mid-combat.

Turret upgrades and selling use one action panel per turret ([turret_hud.tscn](scenes/ui/turret_hud.tscn) → `TurretPanel`) with `Upgrade` and `Sell` `HoldButton`s. Level and health are shown separately by the always-visible `HealthUIComponent` ([health_ui.tscn](scenes/ui/health_ui.tscn)): the level sits in the circle of `turret-health-ui.png` and the health fill in its bar (bar interior is 19 px wide; keep `BAR_WIDTH` in sync if the art changes). The action panel opens whenever the player is in `InteractionZone`; the buttons are shown in build phase only. The panel only emits `upgrade_requested` / `sell_requested`; `TurretHUD` forwards them to `TurretBase.try_upgrade()` / `sell()`. While the Upgrade button is held, `HoldButton.hold_started` / `hold_ended` → `TurretPanel.upgrade_hold_started(hold_duration)` / `upgrade_hold_ended` → `TurretBase.start_upgrade_charge()` / `stop_upgrade_charge()` plays the base `upgrade_charge` animation, speed-scaled so it ends when the hold completes; a completed upgrade plays the `upgrade` animation (white `UpgradeParticles` burst). Both animate `TurretBase.upgrade_whiteness`, which drives the surface shader's `flash_amount`, so sounds and timing are edited in `turret_base.tscn`. `TurretStats.upgrades` is a single ordered `Array[TurretUpgrade]` (`cost`, then `max_health`, `damage`, `attack_range` and `attack_cooldown` as multipliers of the base `TurretStats` value, not of the previous level, e.g. base damage 10 with `damage = 1.5` gives 15; health and damage are rounded to whole numbers; `-1` keeps the previous level's value, and resulting cooldowns below `TurretBase.MIN_ATTACK_COOLDOWN` (0.5 s) are clamped with a warning); the turret is maxed once every entry is applied, there is no wave gate, and when max health changes current health changes by the same amount. When maxed and `stops_targeting_player_when_maxed` is true, the turret's `_stop_targeting_player()` hook runs (Seeker disables its `player` target group, Shockwaver stops triggering on the player); attacks can still damage the player. Selling refunds `sell_refund_ratio × total_invested` (purchase price + upgrades), capped at the player's max capacity, disables the turret, and fades it out; the Upgrade button is hidden once the turret is maxed; `ShopManager` frees the slot and `Player` refunds the capacity.

### Creating a new turret

Use [turret_base.tscn](scenes/world/entities/turret_base.tscn) as the starting template. The base scene already provides common health, repair, upgrade, HUD, interaction, exclusion, range, phase lifecycle, animation, hit particles, death effects, collision, and hit-flash shader setup.

1. Duplicate `turret_base.tscn` and save it as the new turret scene. Keep the common direct-child node names unchanged: `HealthComponent`, `HealthUIComponent`, `InteractionZone`, `TurretUpgradeComponent`, `RepairComponent`, `TurretExclusionZone`, `RangeIndicator`, `TurretHUD`, `AnimationHandler`, `FlashVfx`, `HitParticles`, `WindupParticles`, `RepairParticles`, and `Visuals`.
2. Replace or add the turret artwork below `Visuals`. Put the main body at `Visuals/Sprite2D` or `Visuals/AnimatedSprite2D`; put a rotating cannon at `Visuals/Canon` and its artwork at `Visuals/Canon/Graphics` when the turret has one. Do not move `Visuals`, because inherited animations target that node.
3. Leave the base scene's `surface_shader` assigned. `TurretBase` installs separate materials on the body and cannon visuals at runtime. A missing shader is a configuration error and reports with `push_error`.
4. Add a turret script extending `TurretBase`. Export a stats resource that extends `TurretStats`, call `initialize_base(stats)` (it sets health, repair, upgrades, and the range indicator from `stats.attack_range`), initialize behavior components, and implement the turret's phase hooks (`_on_combat_started()` and `_on_combat_stopped()`) as needed.
5. Keep individual behavior in child components where practical. The turret script owns orchestration and wires those components together; components own their state and emit signals upward.
6. Override `set_damage(value)`, `set_attack_range(value)` and `set_attack_cooldown(value)` so an upgrade's absolute values reach the turret's damage source, attack range (update `range_indicator` too) and attack interval, and `_stop_targeting_player()` so the maxed turret stops selecting the player as a target. Author the upgrade levels in the stats resource's `upgrades` array. Shared per-scene resources a turret mutates on upgrade (e.g. collision shapes) must be duplicated per instance.
7. Add behavior-specific animations to the inherited `AnimationHandler` library. Configure them in the script with `animation.configure_animation(name, priority, locks)` and use node paths relative to `AnimationHandler`. Keep `RESET`, `repair`, and `die` from the base library unless the turret has a deliberate replacement. Damage feedback is shader-driven; the base no longer carries unused idle or take-damage animation clips. If a turret script overrides `_physics_process`, it must call `super._physics_process(delta)` because `TurretBase` runs hold-to-repair there.
8. Add the new turret to its stats/resource files, shop entry, ghost scene, and `ShopManager` entries only after the standalone scene works. Set `TurretEntry.stats` to the turret's stats resource (the placement preview shows its `attack_range`) and author the exclusion radius on the `TurretEntry`.
9. Validate the scene with the editor command, run the scene standalone, and manually verify: health changes on damage, body/cannon flash white, repair and upgrade UI, phase transitions, behavior animation timing, death effects, and placement/shop flow.

### Fail-fast guard policy

Do not use `is_inside_tree()` as a general error-suppression guard around normal calls. If a required node, resource, shader, animation, or component is missing, report it with `push_error` or an assertion so the configuration problem is visible immediately. Early returns are appropriate for expected gameplay state, such as cooldowns, disabled abilities, no target found, unaffordable actions, or a one-shot callback arriving after an object has already been invalidated.

The targeting system retains one explicit tree-membership check because it validates a cached target reference that can outlive or detach from the scene tree during enemy death. That is a stale-reference safety check, not a substitute for required initialization. The orb lifetime timer only checks `can_collect`; its lifecycle is controlled by the node and timer signal rather than silently ignoring a detached node.

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

Targeting uses one generic `TargetingComponent` ([targeting.gd](scripts/world/entities/shared/targeting.gd)) configured by a `TargetingProfile` resource ([resources/enemies/enemy_targeting.tres](resources/enemies/enemy_targeting.tres), [resources/turrets/turret_targeting.tres](resources/turrets/turret_targeting.tres)) referenced from each stats resource (`ChaserStats.targeting`, `StalkerStats.targeting`, `KamikazerStats.targeting`, `SeekerStats.targeting`); Chaser and Stalker share `enemy_targeting.tres`, all Seekers share `turret_targeting.tres`, and the Kamikazer keeps a player-only `kamikazer_targeting.tres`. Resources are grouped by owner: `resources/player/`, `resources/enemies/<enemy>/` (stats, spawn details, own targeting), `resources/turrets/<turret>/` (stats, shop entry), shared profiles at the `enemies/` and `turrets/` roots, and `resources/waves/` (wave, spawn, conveyor settings). A profile has exactly two groups, `primary_group` and `secondary_group` (optional), and these rules run every call to `get_best_target(from, filter)`: (1) candidates must be alive, in an enabled group, within the component's per-instance `max_range`, and pass `filter` (Seeker: line of sight); an invalid current target is dropped with no hysteresis. (2) A primary target within `primary_lock_radius` always wins. (3) Otherwise the secondary target wins when `dist(primary) > dist(secondary) + switch_to_secondary_margin`, and keeps winning until `dist(primary) < dist(secondary) + return_to_primary_margin` (hysteresis band). (4) Within the chosen group the current target is kept unless a challenger satisfies `dist(challenger) + retarget_margin < dist(current)`. `target_changed(new, old)` fires on every switch (Chaser resets its attack latch). Chaser movement: each chaser walks (navigation + avoidance) toward its target plus a personal random `flank_distance` offset that fades from full beyond `flank_full_distance` to zero inside `flank_zero_distance`, so groups fan out and arrive from different sides but always converge on the target itself; the flank is dropped (one-way, reset on target change) once reached. Within 32 px it steers straight at the target. Enemies ride conveyors as passengers (`EnemyBase._add_conveyor_velocity()`): on a belt they stop walking and are carried, so they never fight a belt that is faster than they walk. The floor `TileMapLayer` uses `NavigationMapLayer` ([scripts/world/navigation_map_layer.gd](scripts/world/navigation_map_layer.gd)), which disables per-tile navigation and bakes one navigation mesh at runtime from cells whose tile has a navigation polygon, minus colliders of nodes in the `navigation_obstacles` group (the tilemap itself and the shop station) and conveyor belts (group `conveyor_belts`), eroded by `agent_radius` (14 px, plus `conveyor_clearance` 10 px around belts) so paths keep enemy bodies off walls, corners, and belt edges. All enemies (Chaser, Stalker, Kamikazer) share the same navigation rules: this baked mesh, shortest-path (corridor funnel) routing, conveyor passenger mode, and NavigationAgent2D avoidance with radius 14, neighbor_distance 80, max_neighbors 10, time_horizon_agents 1.5 for spacing (Kamikazer switches avoidance off while charging); the final straight-line approach also goes through avoidance via `NavigationComponent.get_safe_direct_velocity()`. Off-mesh flank points are snapped onto the walkable area rather than dropped. Turrets are not baked in (placed at runtime). Enemies use player-primary / turrets-secondary with a lock radius so the player can pull aggro off turrets; Seekers use enemies-primary / player-secondary and disable the `player` group when maxed. Each `debug_*` flag on a profile draws one ring on the ground for every entity using it (`TargetingDebugDraw`, toggleable live): white = max range, yellow = lock radius, blue = distance to nearest primary, orange = distance to nearest secondary, red = switch ring (primary leaving it -> secondary chosen), purple = return ring (primary entering it -> back to primary), green = retarget ring, plus a line to the current target. The switch/return rings are never drawn smaller than the lock radius, since the lock overrides them.

### Known deliberate deviations from a "pure" component model

A few places intentionally cross the strict ownership boundary because the added indirection isn't worth it for a single-scene game:

- Turret repair drains player capacity directly (`repair.capacity_drained.connect(player.capacity.spend)`) rather than going through an event/coordinator layer.
- Spawners and factories (`ShootComponent`, `EnemySpawner`, `TurretPlacer`) call `get_tree().current_scene.add_child(...)` directly instead of routing through a dedicated spawn coordinator.
- `OrbDropComponent.drop()` looks up the player via `get_tree().get_first_node_in_group("player")` and reads `player.crunch_time.is_crunch_time_active()` directly to skip orb and powerup drops during crunch time, instead of the player broadcasting a "no drops" event enemies subscribe to.
- `TurretBase` reads the `repair` input directly (`Input.is_action_pressed`) instead of the player routing it to the nearest turret; with at most a handful of turrets, a player-side turret selection layer would add more indirection than value.
- `TurretBase` reads `player.capacity.can_afford()` to decide whether the upgrade button is enabled. Spending and refunds still flow as signals (`TurretBase.upgrade_purchased` / `sold` → `ShopManager.turret_upgraded` / `turret_sold` → `Player`); only the read-only affordability check crosses the boundary, because a signal round-trip for a per-frame button state adds no value.

These are acceptable trade-offs, not bugs — revisit only if the game grows multiple scenes or needs pooling/threading.

### Enemy spawn intro

`EnemySpawner` instances can sit outside the playable area and expose `spawn_intro_direction` plus `spawn_intro_distance`. A spawned `EnemyBase` is initially non-colliding, invulnerable, AI-disabled, and visually held on the first idle frame while its root is tweened from the spawner position to the release position. Sleep/wake visuals are editable `spawn_sleep` and `spawn_wake` animations on each enemy scene: sleep tints the body grey, and wake fades it back to normal. On arrival, `EnemyBase` restores collision, contact damage, animation, and normal physics processing, then plays `spawn_wake`. The tween duration is derived as `spawn_intro_distance / ConveyorSettings.enemy_movement_speed`, so its world-space speed matches enemy conveyor movement exactly. This is presentation owned by the spawner and shared enemy base; individual enemy AI scripts do not contain spawn-entry behavior.

Conveyor belts are inline `Area2D` components in the level scene, not standalone scenes. Each uses [scripts/world/spawners/conveyor_belt.gd](scripts/world/spawners/conveyor_belt.gd), detects PlayerBody and EnemyBody layers, and owns a child `CollisionShape2D` whose dimensions are currently authored in the level scene. Both the belt and spawner reference [resources/waves/conveyor_settings.tres](resources/waves/conveyor_settings.tres), the single source of truth for `enemy_movement_speed` and `player_movement_speed`. The belt talks to bodies only through `set_conveyor_velocity()` / `clear_conveyor_velocity()`; while overlapping, the matching conveyor velocity is added to normal player/enemy movement so they can steer off the belt. The spawn tween remains responsible for crossing the outer wall while collision is disabled.

### Wave System

Build-phase duration is configured in [resources/wave_settings.tres](resources/waves/wave_settings.tres) as `build_phase_duration`.

Each `EnemySpawner` builds a finite shuffled queue from [resources/waves/enemy_spawn_stats.tres](resources/waves/enemy_spawn_stats.tres) and spawns it at the configured interval. Each enemy entry owns its enabled state, introduction wave, base amount, multiplicative per-wave amount growth, and cumulative health multiplier interval. Counts are per spawner.

Combat ends only after every spawner finishes its queue and all spawned enemies are dead (not on a timer—victory requires clearing enemies). Pickups remain during build phase and are cleared when the next combat phase begins.

### Type-safety standard

This project uses strict GDScript typing for signal callbacks and loops. Any anonymous function passed to `connect()` must either declare its parameter type(s) or include an explicit `-> void` return type. Any `for` loop variable that is not inference-safe should be explicitly typed, e.g. `for rider: Node in _riders.values():` and `for factor: float in _factors.values():`. If a value can be ambiguous, declare its type explicitly (`var intro_speed: float = ...`). This is not style-only; it keeps Godot diagnostics clean and prevents silent type drift.

### Crunch-time visual effects system

Crunch-time presentation is split between [scripts/data/crunch_time_effects.gd](scripts/data/crunch_time_effects.gd) / [resources/crunch_time_effects.tres](resources/player/crunch_time_effects.tres) and the HUD's editable AnimationPlayer clips in [scenes/ui/hud.tscn](scenes/ui/hud.tscn). The HUD scene owns editor-facing presentation details such as the ready label text and layout. The resource owns state-dependent tuning such as overlay intensity, active camera zoom, and sprite tint. `CrunchTimeComponent` owns the fixed-duration lifecycle and camera transition through a camera reference injected by `Player`; it captures the camera's current zoom on activation and restores that value when crunch time ends. `Player` coordinates gameplay buffs and sprite tint from the component's signals until the component ends the mode. Duration and buffs are authored in [resources/player_stats.tres](resources/player/player_stats.tres). The HUD AnimationPlayer owns the capacity bar's `capacity_ready`, `capacity_active`, and `capacity_change` motion; the ready label's size pulse is a track inside `capacity_ready`. These clips use integer-pixel vertical movement and no scale/rotation on the pixel-art bar, so timing and keyframes can be adjusted directly in the scene editor without subpixel distortion.

### Primary Attack Routing

`Player` routes the primary attack action to `ShootComponent` normally and `MeleeWeapon` during Crunch Time. `MeleeWeapon` handles enemy bodies through `HitboxComponent` and projectile areas through the generic `receive_wrench_hit()` contract. Turrets do not implement that contract; they are repaired only by hold-to-repair.

### Shockwaver Prototype

[scenes/world/entities/shockwaver.tscn](scenes/world/entities/shockwaver.tscn) is registered through [resources/turrets/shockwaver/shockwaver_shop_details.tres](resources/turrets/shockwaver/shockwaver_shop_details.tres), alongside Seeker and Seeker Strong. `ShockwaveComponent` owns contact detection, windup, expanding annulus rendering, one-hit-per-target tracking, multi-target damage, and cooldown. The expanding ring uses [shaders/shockwave_pixel_art.gdshader](shaders/shockwave_pixel_art.gdshader), which generates a symmetric hard-edged ring from quantized fragment coordinates on a dedicated square canvas. Tune `ShockwaveComponent.shockwave_color`, `ShockwaveComponent.pixel_size`, `ShockwaveComponent.center_line_color`, and `ShockwaveComponent.center_line_thickness` in the scene Inspector; these control the ring color, pixel block size, centerline color, and centerline width in pixel-grid cells. The default centerline thickness is one pixel. Knockback is authored as `TurretStats.knockback` on the Shockwaver stats and applies to enemies only; the player is damaged without being pushed. The broad-phase `Area2D` detects player/enemy bodies; radial swept-ring math determines when the moving doughnut reaches each target without scaling collision shapes. `TurretEntry.stats` (typed `TurretStats`) supplies the placement preview range via the shared `attack_range`, and `TurretEntry` owns the exclusion radius; `ShopManager` applies `exclusion_radius` to the placed turret via `TurretBase.set_exclusion_radius()` (turrets not placed through the shop keep the `TurretExclusionZone` default). The Shockwaver uses a single `ShockwaverStats.max_range` as both trigger distance and blast radius.

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
scripts/systems/          WaveManager, ShopManager, ScoreManager, GameOverManager, TurretPlacer, TimeScaleManager
scripts/world/entities/   Player, enemies (Chaser/Stalker/Kamikazer), Turret, shared components
scripts/data/             Resource subclasses (stats)
resources/                .tres stat variants
scripts/ui/               HUD, shop panel, pause menu, turret panels
```
