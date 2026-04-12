extends Node
class_name CapacityManager

signal capacity_changed(amount: float)
signal player_died
signal crunch_time_unlocked

const INITIAL_CAPACITY := 50.0

var current_capacity: float = INITIAL_CAPACITY

func can_afford(cost: float) -> bool:
	return current_capacity - cost >= 1.0

func spend(cost: float) -> void:
	current_capacity = maxf(0.0, current_capacity - cost)
	emit_signal("capacity_changed", current_capacity)
	if current_capacity <= 0.0:
		emit_signal("player_died")

func gain(amount: float) -> void:
	var was_below_max := current_capacity < 100.0
	current_capacity = minf(100.0, current_capacity + amount)
	emit_signal("capacity_changed", current_capacity)
	if was_below_max and current_capacity >= 100.0:
		emit_signal("crunch_time_unlocked")
