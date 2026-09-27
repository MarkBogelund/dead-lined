extends Node
class_name CapacityComponent

## The player's capacity: health and currency in one pool.

signal capacity_changed(amount: float)

@export_group("Capacity")
@export var initial_capacity := 80.0
@export var max_capacity := 100.0

var current_capacity: float

func _ready() -> void:
	current_capacity = initial_capacity

func initialize(p_initial: float, p_max: float) -> void:
	initial_capacity = p_initial
	max_capacity = p_max
	current_capacity = p_initial

func can_afford(cost: float) -> bool:
	return current_capacity - cost >= 1.0

func get_current() -> float:
	return current_capacity

func get_max() -> float:
	return max_capacity

func spend(cost: float) -> void:
	current_capacity = maxf(0.0, current_capacity - cost)
	capacity_changed.emit(current_capacity)

func gain(amount: float) -> void:
	current_capacity = minf(max_capacity, current_capacity + amount)
	capacity_changed.emit(current_capacity)
