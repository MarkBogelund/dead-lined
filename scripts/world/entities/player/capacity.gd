extends Node
class_name CapacityComponent

signal capacity_changed(amount: float)
signal crunch_time_unlocked
signal crunch_time_threshold_changed(new_threshold: float)

@export_group("Capacity")
@export var initial_capacity := 80.0
@export var max_capacity := 100.0

@export_group("Crunch Time")
@export var crunch_threshold := 90.0
@export var threshold_step := 10.0
@export var min_crunch_threshold := 10.0

var current_capacity: float
var crunch_time_threshold: float

func _ready() -> void:
	current_capacity = initial_capacity
	crunch_time_threshold = crunch_threshold

func initialize(p_initial: float, p_max: float, p_threshold: float, p_step: float, p_min: float) -> void:
	initial_capacity = p_initial
	max_capacity = p_max
	crunch_threshold = p_threshold
	threshold_step = p_step
	min_crunch_threshold = p_min
	current_capacity = p_initial
	crunch_time_threshold = p_threshold

func can_afford(cost: float) -> bool:
	return current_capacity - cost >= 1.0

func can_crunch_time() -> bool:
	return current_capacity >= crunch_time_threshold

func lower_threshold() -> void:
	crunch_time_threshold = maxf(min_crunch_threshold, crunch_time_threshold - threshold_step)
	emit_signal("crunch_time_threshold_changed", crunch_time_threshold)

func raise_threshold() -> void:
	crunch_time_threshold = minf(crunch_threshold, crunch_time_threshold + threshold_step)
	emit_signal("crunch_time_threshold_changed", crunch_time_threshold)

func spend(cost: float) -> void:
	current_capacity = maxf(0.0, current_capacity - cost)
	emit_signal("capacity_changed", current_capacity)

func gain(amount: float) -> void:
	var was_below_threshold := not can_crunch_time()
	current_capacity = minf(max_capacity, current_capacity + amount)
	emit_signal("capacity_changed", current_capacity)
	if was_below_threshold and can_crunch_time():
		emit_signal("crunch_time_unlocked")
