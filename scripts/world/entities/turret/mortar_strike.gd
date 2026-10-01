extends Node2D
class_name MortarStrike

enum State {TELEGRAPH, FLIGHT, IMPACT}

@onready var radial_wave: ShockwaveComponent = $RadialWaveComponent

@export var marker_color := Color(1.0, 0.35, 0.15, 0.32)
@export var shell_color := Color(1.0, 0.78, 0.25, 1.0)

var _state := State.TELEGRAPH
var _origin := Vector2.ZERO
var _flight_duration := 0.8
var _arc_height := 36.0
var _elapsed := 0.0

func _ready() -> void:
	radial_wave.shockwave_finished.connect(queue_free)

func setup(
		impact_position: Vector2,
		blast_radius: float,
		ring_thickness: float,
		expansion_duration: float,
		damage: int,
		knockback: float) -> void:
	global_position = impact_position
	radial_wave.auto_trigger = false
	radial_wave.configure(blast_radius, ring_thickness, 0.0, expansion_duration, damage, knockback)
	radial_wave.set_enabled(true)
	_state = State.TELEGRAPH
	queue_redraw()

func launch(origin: Vector2, flight_duration: float, arc_height: float) -> void:
	_origin = origin
	_flight_duration = maxf(0.05, flight_duration)
	_arc_height = maxf(0.0, arc_height)
	_elapsed = 0.0
	_state = State.FLIGHT
	queue_redraw()

func _process(delta: float) -> void:
	if _state != State.FLIGHT:
		return
	_elapsed += delta
	var progress := minf(_elapsed / _flight_duration, 1.0)
	queue_redraw()
	if progress >= 1.0:
		_state = State.IMPACT
		radial_wave.execute_shockwave()
		queue_redraw()

func _draw() -> void:
	if _state == State.TELEGRAPH:
		draw_circle(Vector2.ZERO, radial_wave.max_range, marker_color)
		draw_arc(Vector2.ZERO, radial_wave.max_range, 0.0, TAU, 64, marker_color.lightened(0.35), 2.0)
		return
	if _state == State.IMPACT:
		return
	var progress := minf(_elapsed / _flight_duration, 1.0)
	var shell_position := _origin - global_position
	shell_position = shell_position.lerp(Vector2.ZERO, progress)
	shell_position.y -= sin(progress * PI) * _arc_height
	draw_circle(shell_position, 5.0, shell_color)
	draw_circle(shell_position + Vector2(0, 4), 3.0, Color(0, 0, 0, 0.35))
