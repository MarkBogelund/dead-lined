# Architecture Guidelines

This document outlines the core architectural principles for this Godot project to ensure modularity, scalability, and maintainability.

---

## Core Principles

### 1. Component Ownership
**Components own their state and functionality completely.**

- A component's state can **ONLY** be modified by the component itself
- Components are self-contained and encapsulate their behavior
- No external code should directly modify a component's internal state
- Components expose a clean public interface: methods to trigger behaviour, signals to report events

```gdscript
# ✅ GOOD - Component owns its state
class_name CapacityComponent
var current_capacity: float  # Managed internally

func spend(amount: float) -> void:
    current_capacity -= amount  # Component modifies its own state
    capacity_changed.emit(current_capacity)

# ❌ BAD - External modification
player.capacity.current_capacity -= 10  # Violation of ownership
```

---

### 2. Loose Coupling
**Minimize dependencies between components.**

#### Node Reference Rules

**Own child nodes** (packed scene children, `$` path):
```gdscript
# ✅ GOOD - Direct child lookup within the same packed scene
@onready var dash: DashComponent = $DashComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
```

**Scene-wide unique nodes** (`%` unique name):
- Use `%UniqueName` for nodes outside your packed scene that have `unique_name_in_owner = true`
- Requires both nodes to share the same scene owner (e.g. both in game.tscn)
```gdscript
# ✅ GOOD - Scene-wide manager via unique name
@onready var wave_manager: WaveManager = %WaveManager
@onready var camera_shake_manager = %CameraShakeManager
```

**Cross-scene references** (`@export`):
- Use `@export` when the reference cannot be resolved by unique name (different owners)
```gdscript
# ✅ GOOD - Inspector-assigned reference
@export var player: Player
@export var shop_panel: ShopPanel
```

**Dynamically instantiated nodes** (created at runtime):
- Use `get_tree().get_first_node_in_group()` for singleton managers
```gdscript
# ✅ GOOD - Dynamic node finding singleton managers
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")
```

**Entity collections** (groups):
```gdscript
# ✅ GOOD - Groups for collections of entities
func find_nearest_enemy() -> Node2D:
    var enemies = get_tree().get_nodes_in_group("enemies")
    # ... find closest
```

```gdscript
# ❌ BAD - Hard-coded absolute path
@onready var player = $"/root/Game/World/Player"

# ❌ BAD - % on a node that is not unique_name_in_owner or is in a different owner
@onready var capacity: CapacityComponent = %CapacityComponent  # wrong if added in a parent scene
```

---

### 3. Communication Hierarchy

**Bottom-Up: Components signal upward**
- Components emit signals to notify parents/orchestrators of events
- Keep signal parameters minimal (only essential data)
- Components never reference their parent or siblings directly

```gdscript
# In CrunchTimeComponent
signal drain_tick
signal crunch_time_started(buffs: Dictionary)
signal crunch_time_ended(buffs: Dictionary)

func _process(delta: float) -> void:
    # ... drain logic
    drain_tick.emit()
```

**Top-Down: Orchestrators call components directly**
- Complex entities (Player, Enemy) act as orchestrators for their components
- The orchestrator wires all signal connections in `_connect_signals()` during `_ready()`
- Components never reference each other; the orchestrator bridges them

```gdscript
# In Player (orchestrator)
func _connect_signals() -> void:
    # Wire component events to orchestrator handlers
    crunch_time.drain_tick.connect(_on_crunch_drain_tick)
    crunch_time.crunch_time_started.connect(_on_crunch_time_started)
    # Wire system events to component setters via lambdas when trivial
    wave_manager.build_phase_started.connect(func(): crunch_time.set_build_phase(true))
    # Wire system signals to orchestrator handlers
    shop_manager.turret_bought.connect(_on_turret_bought)

func _on_turret_bought(price: float) -> void:
    capacity.spend(price)       # Orchestrator bridges: shop event → capacity component
    capacity.lower_threshold()
```

**Systems signal outward, not inward**
- Systems (ShopManager, WaveManager) emit signals describing what happened
- They do not reach into Player or its components directly
- This keeps systems decoupled from the entity layer

```gdscript
# ✅ GOOD - ShopManager emits events, Player reacts
signal turret_bought(price: float)
signal turret_lost

func _on_turret_placed(turret: Node, turret_entry: TurretEntry) -> void:
    turret_bought.emit(turret_entry.price)  # System announces the event

# ❌ BAD - System directly manipulates player internals
capacity_manager.spend(turret_entry.price)  # System reaches into player's component
```

**Factories connect signals, never set properties**
- When a factory instantiates a node, do not assign properties on it from the outside
- Property assignment from outside breaks component ownership; use signal connections or let the node resolve its own dependencies via `get_first_node_in_group`

```gdscript
# ❌ BAD - Factory sets properties on the instantiated node
var turret := turret_scene.instantiate()
turret.wave_manager = wave_manager       # Factory reaching into the node's internals
turret.game_over_manager = game_over_manager
```

---

### 4. `try_*` Methods for Fallible Actions
**Component actions that may fail return `bool`.**

- The caller decides what to do on success (play animation, spend resource, etc.)
- The component stays decoupled from upstream side effects

```gdscript
# ✅ GOOD - try_* returns bool, caller handles success
if melee_weapon.try_slash(mouse_pos):
    _set_facing(mouse_pos.x - global_position.x)
    animation.play_animation("slash")

if dash.try_dash(dash_dir):
    _handle_dash_started(dash_dir)

# ❌ BAD - Component triggers side effects itself
# (would require component to know about animation, audio, etc.)
melee_weapon.slash(mouse_pos)  # Internally plays animation and shakes camera
```

---

### 5. Computed Properties for Derived State
**Use GDScript property getters instead of query methods for boolean/derived state.**

```gdscript
# ✅ GOOD - Computed property
var can_pickup: bool:
    get: return not crunch_time.is_crunch_time_active() and capacity.current_capacity < 100.0

# Usage is natural
if body.can_pickup:
    body.pickup(value)
```

---

## Architecture Layers

Maintain clear separation between layers:

1. **Data Layer** - Pure data tracking (no dependencies on other systems)
   - Example: `CapacityComponent`, `StatsManager`
   
2. **Systems Layer** - Flow control and cross-entity coordination
   - Example: `GameOverManager`, `WaveManager`, `ShopManager`
   
3. **UI Layer** - Display and user interaction
   - Example: `HUD`, `ShopPanel`
   
4. **World Layer** - Game objects with component composition
   - Example: `Player`, `Chaser`, `Turret`
   - Orchestrators in this layer wire together their own components and react to system signals

---

## `_ready()` Structure for Complex Entities

Split `_ready()` into focused helpers when setup is non-trivial:

```gdscript
func _ready() -> void:
    _setup_animations()   # Configure component state/data
    _connect_signals()    # Wire all signal connections

func _setup_animations() -> void:
    animation.configure_animation("idle", 0, false)
    # ...

func _connect_signals() -> void:
    # Components section
    crunch_time.drain_tick.connect(_on_crunch_drain_tick)
    # Systems section
    wave_manager.build_phase_started.connect(func(): crunch_time.set_build_phase(true))
```

Use inline lambdas for trivial one-liner connections; use named handlers when the body is more than one line.

---

## Implementation Checklist

When creating or refactoring a component, verify:
- [ ] Does it own its state? (No external code modifies internals directly)
- [ ] Is it loosely coupled? (Own children via `$`, scene-wide via `%`, cross-scene via `@export`)
- [ ] Does it signal upward for events? (Not call methods on its parent or owner)
- [ ] Do fallible actions return `bool`? (`try_dash`, `try_slash`, etc.)
- [ ] Does the orchestrator do all cross-component wiring in `_connect_signals()`?
- [ ] Do systems emit events rather than calling into player components?

---

## Quick Reference

| Pattern | Use When | Example |
|---------|----------|---------|
| **`$ChildName`** | Own child nodes within the same packed scene | `@onready var dash = $DashComponent` |
| **`%UniqueName`** | Scene-wide unique nodes (same owner) | `@onready var manager = %WaveManager` |
| **`@export`** | Cross-scene references, inspector-assigned | `@export var player: Player` |
| **`get_first_node_in_group()`** | Dynamic nodes — singleton managers at runtime | `get_tree().get_first_node_in_group("mgr")` |
| **`get_nodes_in_group()`** | Collections of entities | `get_tree().get_nodes_in_group("enemies")` |
| **Signal** | Component → orchestrator event notification | `drain_tick.emit()` |
| **`try_*` method** | Fallible component action | `if dash.try_dash(dir):` |
| **Computed property** | Derived boolean/state | `var can_pickup: bool: get: return ...` |
| **`_connect_signals()`** | Centralised wiring in orchestrator `_ready` | Player wires all components + systems |

---

*Keep components independent, communication clear, and dependencies minimal.*

---

## Stats Resources

All balancing values for an entity live in a single `Resource` subclass. Components and entities never hardcode numbers — they read from the stats resource.

### Defining a stats resource

```gdscript
# scripts/data/seeker_stats.gd
extends Resource
class_name SeekerStats

@export_group("Health")
@export var max_health: int = 100

@export_group("Shooting")
@export var shoot_cooldown: float = 0.5
@export var projectile_damage: int = 20

@export_group("Upgrades")
@export var upgrade_cost: float = 15.0
@export var health_upgrade_amount: int = 10
```

- Extends `Resource` (not `Node`) — no scene needed, pure data
- Use `@export_group` to organise values by system (Health, Movement, Shooting, etc.)
- Default values in the script are the canonical fallback; `.tres` files override them per variant

### Creating a variant

1. In the Godot editor: **right-click** `resources/` → **New Resource** → select your stats class
2. Or duplicate an existing `.tres` and change the values
3. Save as e.g. `resources/seeker_strong_stats.tres`

The `.tres` file only stores properties that differ from the script defaults:

```
# resources/seeker_stats.tres
[resource]
script = ExtResource("seeker_stats.gd")
max_health = 200
max_range = 170.0
accuracy_angle = 0.15
```

### Wiring to an entity

The entity exposes the resource as an `@export` and reads from it in `_initialize()`:

```gdscript
# Entity (e.g. Turret / Chaser)
@export var stats: SeekerStats

func _ready() -> void:
    _initialize()

func _initialize() -> void:
    if not stats:
        return
    health.initialize(stats.max_health)
    shoot.shoot_cooldown = stats.shoot_cooldown
    shoot.projectile_damage = stats.projectile_damage
```

Assign the `.tres` file to the `stats` export in the scene inspector (or per-instance in the parent scene). Components receive values through their own initialise methods — they never hold a reference to the stats resource directly.

### Rules

- **One resource per entity type.** `SeekerStats`, `StalkerStats`, `PlayerStats` — not one god resource.
- **Components don't hold the resource.** The entity reads from stats in `_initialize()` and pushes values into components. Components stay decoupled.
- **Variants by `.tres`, not by code.** A `SeekerStrong` is the same scene/script as `Seeker` with a different `stats` assigned — no subclassing needed.
- **Runtime mutations go on the component, not the resource.** If an upgrade increases `projectile_damage`, update `shoot.projectile_damage` directly. The resource stays read-only.

