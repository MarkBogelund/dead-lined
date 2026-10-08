extends Area2D
class_name GhostTurret

## Visual feedback colors
@export var valid_color := Color(0.5, 1.0, 0.5, 0.7) # Green/transparent
@export var invalid_color := Color(1.0, 0.5, 0.5, 0.7) # Red/transparent

## Range indicator (-1 = no indicator)
var range_radius: float = -1.0
var exclusion_radius: float = -1.0

## Component references
@onready var sprite: Sprite2D = $Sprite2D
@onready var exclusion_zone: TurretExclusionZone = $TurretExclusionZone
@onready var range_indicator: RangeIndicator = $RangeIndicator

## State
var is_valid := true
var overlapping_count := 0
var _in_exclusion_zone := false
var _icon: Texture2D

func initialize(p_range_radius: float, p_exclusion_radius: float, p_icon: Texture2D) -> void:
	range_radius = p_range_radius
	exclusion_radius = p_exclusion_radius
	_icon = p_icon

func _ready() -> void:
	sprite.texture = _icon
	# Connect signals directly to self
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	if exclusion_radius > 0.0:
		exclusion_zone.initialize(exclusion_radius)
	
	if range_radius > 0.0:
		range_indicator.initialize(range_radius)
		range_indicator.show_indicator()
	else:
		range_indicator.hide_indicator()
	
	# Initial visual update
	_update_visual_feedback()

func _process(_delta: float) -> void:
	_check_turret_proximity()

func _check_turret_proximity() -> void:
	var was_in_zone := _in_exclusion_zone
	_in_exclusion_zone = false
	for zone: Node in get_tree().get_nodes_in_group("turret_exclusion_zones"):
		if zone is Node2D and zone.get_parent() != self:
			if global_position.distance_to(zone.global_position) < zone.exclusion_radius:
				_in_exclusion_zone = true
				break
	if _in_exclusion_zone != was_in_zone:
		_check_placement_validity()

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
	is_valid = overlapping_count == 0 and not _in_exclusion_zone
	_update_visual_feedback()

func _update_visual_feedback() -> void:
	var target_color := valid_color if is_valid else invalid_color
	
	# Update sprite color
	if sprite:
		sprite.modulate = target_color
	exclusion_zone.set_invalid(not is_valid)

## Public API for TurretPlacer to check before placing
func is_placement_valid() -> bool:
	return is_valid
