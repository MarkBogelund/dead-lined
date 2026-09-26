extends Node2D
class_name ChaserDebugDraw

## Movement overlay for one Chaser; enabled via ChaserStats.debug_movement. Coordinates are relative to the chaser.

const FLANK_FULL_COLOR := Color(1.0, 0.6, 0.2, 0.35)
const FLANK_ZERO_COLOR := Color(1.0, 0.3, 0.3, 0.5)
const DIRECT_COLOR := Color(1.0, 1.0, 1.0, 0.5)
const GOAL_COLOR := Color(1.0, 0.2, 1.0, 0.9)
const PATH_END_COLOR := Color(0.2, 1.0, 1.0, 0.9)
const PATH_COLOR := Color(0.2, 1.0, 1.0, 0.4)
const NEXT_POINT_COLOR := Color(1.0, 1.0, 0.2, 0.9)
const VELOCITY_COLOR := Color(0.3, 1.0, 0.3, 0.9)
const TEXT_OFFSET := Vector2(-20, -18)
const FONT_SIZE := 8

var target_offset := Vector2.ZERO
var flank_full_distance := 0.0
var flank_zero_distance := 0.0
var direct_distance := 0.0
var goal := Vector2.ZERO
var path_end := Vector2.ZERO
var next_point := Vector2.ZERO
var path: PackedVector2Array = []
var velocity_vector := Vector2.ZERO
var status := ""

func _draw() -> void:
	draw_arc(target_offset, flank_full_distance, 0.0, TAU, 48, FLANK_FULL_COLOR, 1.0)
	draw_arc(target_offset, flank_zero_distance, 0.0, TAU, 48, FLANK_ZERO_COLOR, 1.0)
	draw_arc(target_offset, direct_distance, 0.0, TAU, 32, DIRECT_COLOR, 1.0)
	if path.size() >= 2:
		draw_polyline(path, PATH_COLOR, 1.0)
	draw_line(Vector2.ZERO, goal, GOAL_COLOR, 1.0)
	draw_circle(goal, 2.0, GOAL_COLOR)
	_draw_cross(path_end, PATH_END_COLOR)
	draw_circle(next_point, 1.5, NEXT_POINT_COLOR)
	draw_line(Vector2.ZERO, velocity_vector * 0.5, VELOCITY_COLOR, 1.0)
	draw_string(ThemeDB.fallback_font, TEXT_OFFSET, status, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)

func _draw_cross(at: Vector2, color: Color) -> void:
	draw_line(at + Vector2(-3, -3), at + Vector2(3, 3), color, 1.0)
	draw_line(at + Vector2(-3, 3), at + Vector2(3, -3), color, 1.0)
