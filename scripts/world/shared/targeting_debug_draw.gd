extends Node2D
class_name TargetingDebugDraw

## Ground overlay for TargetingComponent decisions; each ring is toggled by a TargetingProfile debug_* flag.

const LOCK_COLOR := Color(1.0, 0.9, 0.2, 0.6)
const PRIMARY_COLOR := Color(0.3, 0.8, 1.0, 0.6)
const SECONDARY_COLOR := Color(1.0, 0.55, 0.15, 0.6)
const SWITCH_COLOR := Color(1.0, 0.2, 0.2, 0.8)
const RETURN_COLOR := Color(0.75, 0.35, 1.0, 0.8)
const RETARGET_COLOR := Color(0.3, 1.0, 0.4, 0.6)
const RANGE_COLOR := Color(1.0, 1.0, 1.0, 0.2)
const SEGMENTS := 48

var profile: TargetingProfile
var max_range := -1.0
var lock_radius := -1.0
var primary_distance := -1.0
var secondary_distance := -1.0
var switch_radius := -1.0
var return_radius := -1.0
var retarget_radius := -1.0
var target_offset := Vector2.ZERO
var target_is_primary := false

func _draw() -> void:
	if profile.debug_max_range:
		_circle(max_range, RANGE_COLOR)
	if profile.debug_lock_radius:
		_circle(lock_radius, LOCK_COLOR)
	if profile.debug_primary_distance:
		_circle(primary_distance, PRIMARY_COLOR)
	if profile.debug_secondary_distance:
		_circle(secondary_distance, SECONDARY_COLOR)
	if profile.debug_switch_ring:
		_circle(switch_radius, SWITCH_COLOR)
	if profile.debug_return_ring:
		_circle(return_radius, RETURN_COLOR)
	if profile.debug_retarget_ring:
		_circle(retarget_radius, RETARGET_COLOR)
	if profile.debug_target_line and target_offset != Vector2.ZERO:
		draw_line(Vector2.ZERO, target_offset, PRIMARY_COLOR if target_is_primary else SECONDARY_COLOR, 1.0)

func _circle(radius: float, color: Color) -> void:
	if radius > 0.0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENTS, color, 1.0)
