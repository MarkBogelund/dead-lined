extends Node
class_name RepairComponent

## Pure math component. No knowledge of zones, players, or other components.
## Call initialize() with stats, then call try_repair(delta, available_capacity) each frame
## while repairing, and reset() when repair is interrupted.

signal repaired(amount: int)
signal capacity_drained(amount: float)

var _capacity_drain_rate := 0.0
var _health_restore_rate := 0.0
var _accumulator := 0.0

func initialize(capacity_drain_rate: float, health_restore_rate: float) -> void:
	_capacity_drain_rate = capacity_drain_rate
	_health_restore_rate = health_restore_rate

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

func get_capacity_cost(delta: float) -> float:
	return _capacity_drain_rate * delta

func reset() -> void:
	_accumulator = 0.0
