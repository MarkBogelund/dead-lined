extends Area2D
class_name GhostTurret

## Visual feedback colors
@export var valid_color := Color(0.5, 1.0, 0.5, 0.7) # Green/transparent
@export var invalid_color := Color(1.0, 0.5, 0.5, 0.7) # Red/transparent
@export var range_color := Color(1.0, 1.0, 1.0, 0.4) # Neutral white

## Range indicator (-1 = no indicator)
var range_radius: float = -1.0

## Component references
@onready var sprite: Sprite2D = $Sprite2D

## State
var is_valid := true
var overlapping_count := 0

func _ready() -> void:
	# Connect signals directly to self
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Initial visual update
	_update_visual_feedback()
func _on_body_entered(_body: Node2D) -> void:
	overlapping_count += 1
	_check_placement_validity()

func _on_body_exited(_body: Node2D) -> void:
	overlapping_count -= 1
	_check_placement_validity()

func _on_area_entered(_area: Area2D) -> void:
	overlapping_count += 1
	_check_placement_validity()

func _on_area_exited(_area: Area2D) -> void:
	overlapping_count -= 1
	_check_placement_validity()

func _check_placement_validity() -> void:
	is_valid = overlapping_count == 0
	_update_visual_feedback()

func _update_visual_feedback() -> void:
	var target_color := valid_color if is_valid else invalid_color
	
	# Update sprite color
	if sprite:
		sprite.modulate = target_color
	queue_redraw()

func _draw() -> void:
	if range_radius > 0.0:
		draw_arc(Vector2.ZERO, range_radius, 0.0, TAU, 64, range_color, 1.0)

## Public API for TurretPlacer to check before placing
func is_placement_valid() -> bool:
	return is_valid
