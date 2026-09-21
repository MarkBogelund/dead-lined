extends Node
class_name RepairComponent

## Pure math component. No knowledge of zones, players, or other components.
## Call initialize() with stats, then call try_repair(delta, available_capacity) each frame
## when the player is in range and holding the repair input.
## Call reset() when repair should be interrupted.

signal repaired(amount: int)
signal capacity_drained(amount: float)
signal healing_started
signal healing_stopped

var _capacity_drain_rate := 0.0
var _health_restore_rate := 0.0
var _repair_amount_per_wrench_hit := 0
var _accumulator := 0.0

func initialize(capacity_drain_rate: float, health_restore_rate: float, repair_amount_per_wrench_hit: int) -> void:
	_capacity_drain_rate = capacity_drain_rate
	_health_restore_rate = health_restore_rate
	_repair_amount_per_wrench_hit = repair_amount_per_wrench_hit

func try_repair(delta: float, available_capacity: float) -> void:
	var drain := _capacity_drain_rate * delta
	if drain > available_capacity:
		_accumulator = 0.0
		return
	capacity_drained.emit(drain)
	_accumulator += _health_restore_rate * delta
	var to_heal := int(_accumulator)
	if to_heal > 0:
		repaired.emit(to_heal)
		_accumulator -= float(to_heal)

func repair_once() -> void:
	repaired.emit(_repair_amount_per_wrench_hit)

func reset() -> void:
	_accumulator = 0.0

func activate() -> void:
	healing_started.emit()

func deactivate() -> void:
	reset()
	healing_stopped.emit()
