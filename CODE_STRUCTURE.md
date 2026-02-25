# Architecture Guidelines

This document outlines the core architectural principles for this Godot project to ensure modularity, scalability, and maintainability.

---

## Core Principles

### 1. Component Ownership
**Components own their state and functionality completely.**

- A component's state can **ONLY** be modified by the component itself
- Components are self-contained and encapsulate their behavior
- No external code should directly modify a component's internal state
- Components expose public methods to report events, not to allow state mutation

```gdscript
# ✅ GOOD - Component owns its state
class_name HealthComponent
var current_health: int  # Private, managed internally

func take_damage(amount: int) -> void:
    current_health -= amount  # Component modifies its own state

# ❌ BAD - External modification
player.health.current_health -= 10  # Violation of ownership
```

---

### 2. Loose Coupling
**Minimize dependencies between components.**

#### Static vs Dynamic Node References

**Static scene nodes** (exist at compile/load time):
- Use `@export` variables assigned in the inspector, OR
- Use `@onready` with `%UniqueName` syntax for managers

**Dynamically instantiated nodes** (created at runtime):
- Use `get_tree().get_first_node_in_group()` for singleton managers


```gdscript
✅ GOOD - Static node using @export (assigned in inspector)
@export var player: Player

func _ready() -> void:
    player.died.connect(_on_player_died)

✅ GOOD - Static node using %UniqueName
@onready var resource_manager = %ResourceManager

✅ GOOD - Dynamic node finding singleton managers
@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")

func _ready() -> void:
    wave_manager.combat_phase_started.connect(_on_combat_started)

✅ GOOD - Groups for collections of entities
func find_nearest_enemy() -> Node2D:
    var enemies = get_tree().get_nodes_in_group("enemies")
    # ... find closest

❌ BAD - Hard-coded path creates tight coupling
@onready var player = $"/root/Game/World/Player"

❌ BAD - Dynamic node trying to use %UniqueName (will be null)
# This fails for instantiated scenes - no owner!
@onready var wave_manager = %WaveManager
```

---

### 3. Communication Hierarchy

**Bottom-Up: Components signal to parents and siblings**
- Entities use **signals** to notify parents/siblings of events
- Keep signal parameters minimal (only essential data)

```gdscript
# In entity
signal died
signal damaged(amount: int)

func _on_health_depleted() -> void:
    died.emit()  # Tell interested parties what happened
```

**Top-Down: Managers call subordinates directly**
- Managers act as "glue code" coordinating between systems
- Managers can directly call methods on children/subordinates
- Reference subordinates via `@export` variables or `@onready` child lookups

```gdscript
# In manager - export reference assigned in inspector
@export var game_over_ui: Control

func player_died() -> void:
    if game_over_ui and game_over_ui.has_method("show_stats"):
        game_over_ui.show_stats(stats)  # Manager calls subordinate

# Alternative - direct child reference
@onready var ui = $GameOverUI
```

**Lateral: Components push data when requested**
- Use the **Push Model** - components actively provide their data
- On shared events, components push their state to coordinating managers
- Avoids tight coupling from managers querying components

```gdscript
# In component
func _ready() -> void:
    GameOverManager.game_over.connect(_on_game_over)

func _on_game_over() -> void:
    StatsManager.set_waves(current_wave)  # Push data to manager
```

---

## Architecture Layers

Maintain clear separation between layers:

1. **Data Layer** - Pure data tracking (no dependencies on other managers)
   - Example: `StatsManager`, `ResourceManager`
   
2. **Coordination Layer** - Flow control and glue code
   - Example: `GameOverManager`, `WaveManager`
   
3. **UI Layer** - Display and user interaction
   - Example: `HUD`, `ShopPanel`
   
4. **World Layer** - Game objects with component composition
   - Example: `Player`, `Chaser`, `Turret`

---

## Implementation Checklist

When creating or refactoring a component, verify:
- [ ] Does it own its state? (External code can't modify internals)
- [ ] Is it loosely coupled? (Static nodes use @export/%UniqueName, dynamic nodes use groups)
- [ ] Does it signal upward for events? (Not call methods on parents)
- [ ] Can managers safely call it? (Has well-defined public interface)
- [ ] Does it push data instead of being queried? (Active, not passive)

---

## Quick Reference

| Pattern | Use When | Example |
|---------|----------|---------|
| **@export** | Static nodes - single references in inspector | `@export var player: Player` |
| **%UniqueName** | Static nodes - managers with unique names | `@onready var manager = %WaveManager` |
| **get_first_node_in_group()** | Dynamic nodes - finding singleton managers | `get_tree().get_first_node_in_group("wave_manager")` |
| **get_nodes_in_group()** | Collections of entities (static or dynamic) | `get_tree().get_nodes_in_group("enemies")` |
| **Signal** | Notifying parents/siblings of events | `died.emit()` |
| **Direct Call** | Manager → subordinate coordination | `ui.show_stats(data)` |
| **Push Data** | Responding to system-wide events | `StatsManager.set_waves(count)` |

---

*Keep components independent, communication clear, and dependencies minimal.*

