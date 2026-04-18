extends Node
class_name CapacityComponent

signal capacity_changed(amount: float)
signal crunch_time_unlocked
signal crunch_time_threshold_changed(new_threshold: float)

@export_group("Capacity Costs")
@export var shoot_cost: float = 2.0

const INITIAL_CAPACITY := 80.0
const BASE_CRUNCH_THRESHOLD := 90.0
const THRESHOLD_STEP := 10.0
const MIN_CRUNCH_THRESHOLD := 10.0

var current_capacity: float = INITIAL_CAPACITY
var crunch_time_threshold: float = BASE_CRUNCH_THRESHOLD

func can_afford(cost: float) -> bool:
	return current_capacity - cost >= 1.0

func can_crunch_time() -> bool:
	return current_capacity >= crunch_time_threshold

func lower_threshold() -> void:
	crunch_time_threshold = maxf(MIN_CRUNCH_THRESHOLD, crunch_time_threshold - THRESHOLD_STEP)
	emit_signal("crunch_time_threshold_changed", crunch_time_threshold)

func raise_threshold() -> void:
	crunch_time_threshold = minf(BASE_CRUNCH_THRESHOLD, crunch_time_threshold + THRESHOLD_STEP)
	emit_signal("crunch_time_threshold_changed", crunch_time_threshold)

func spend(cost: float) -> void:
	current_capacity = maxf(0.0, current_capacity - cost)
	emit_signal("capacity_changed", current_capacity)

func gain(amount: float) -> void:
	var was_below_threshold := not can_crunch_time()
	current_capacity = minf(100.0, current_capacity + amount)
	emit_signal("capacity_changed", current_capacity)
	if was_below_threshold and can_crunch_time():
		emit_signal("crunch_time_unlocked")
