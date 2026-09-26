extends Node2D
class_name TargetingDebugDraw

## Ground overlay for TargetingComponent decisions; enabled via TargetingProfile.debug_draw.

const LOCK_COLOR := Color(1.0, 0.9, 0.2, 0.6)
const HIGH_COLOR := Color(0.3, 0.8, 1.0, 0.6)
const LOW_COLOR := Color(1.0, 0.55, 0.15, 0.6)
const SWITCH_COLOR := Color(1.0, 0.2, 0.2, 0.8)
const TAKEOVER_COLOR := Color(0.3, 1.0, 0.4, 0.6)
const RANGE_COLOR := Color(1.0, 1.0, 1.0, 0.2)
const SEGMENTS := 48

var lock_radius := -1.0
var max_range := -1.0
var high_distance := -1.0
var low_distance := -1.0
## High-priority target outside this circle -> the low-priority target is chosen.
var switch_radius := -1.0
## A same-priority challenger inside this circle takes over the current target.
var takeover_radius := -1.0
var target_offset := Vector2.ZERO
var target_is_high := false

func _draw() -> void:
	_circle(max_range, RANGE_COLOR)
	_circle(lock_radius, LOCK_COLOR)
	_circle(high_distance, HIGH_COLOR)
	_circle(low_distance, LOW_COLOR)
	_circle(switch_radius, SWITCH_COLOR)
	_circle(takeover_radius, TAKEOVER_COLOR)
	if target_offset != Vector2.ZERO:
		draw_line(Vector2.ZERO, target_offset, HIGH_COLOR if target_is_high else LOW_COLOR, 1.0)

func _circle(radius: float, color: Color) -> void:
	if radius > 0.0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENTS, color, 1.0)
