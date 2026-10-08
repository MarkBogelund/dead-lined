extends Node2D
class_name MortarStrike

enum State {TELEGRAPH, FLIGHT, IMPACT}

@onready var radial_wave: RadialWaveComponent = $RadialWaveComponent
@onready var shell: Sprite2D = $Shell
@onready var shadow: Sprite2D = $Shadow

@export var marker_color := Color(1.0, 0.35, 0.15, 0.32)
var _state := State.TELEGRAPH
var _origin := Vector2.ZERO
var _flight_duration := 0.8
var _arc_height := 36.0
var _elapsed := 0.0
var _shell_scale := Vector2.ONE

func _ready() -> void:
	radial_wave.shockwave_finished.connect(queue_free)
	_shell_scale = shell.scale

func setup(
		impact_position: Vector2,
		blast_radius: float,
		expansion_duration: float,
		damage: int,
		knockback: float) -> void:
	global_position = impact_position
	radial_wave.auto_trigger = false
	radial_wave.configure_manual(blast_radius, expansion_duration, damage, knockback)
	radial_wave.set_enabled(true)
	_state = State.TELEGRAPH
	shell.hide()
	shadow.hide()
	queue_redraw()

func launch(origin: Vector2, flight_duration: float, arc_height: float) -> void:
	_origin = origin
	_flight_duration = maxf(0.05, flight_duration)
	_arc_height = maxf(0.0, arc_height)
	_elapsed = 0.0
	_state = State.FLIGHT
	shell.scale.x = absf(_shell_scale.x) * (-1.0 if _origin.x > global_position.x else 1.0)
	shell.show()
	shadow.show()
	queue_redraw()

func _process(delta: float) -> void:
	if _state != State.FLIGHT:
		return
	_elapsed += delta
	var progress := minf(_elapsed / _flight_duration, 1.0)
	var straight_position := (_origin - global_position).lerp(Vector2.ZERO, progress)
	shadow.position = straight_position
	var shell_position := straight_position
	shell_position.y -= sin(progress * PI) * _arc_height
	shell.position = shell_position
	queue_redraw()
	if progress >= 1.0:
		_state = State.IMPACT
		shell.hide()
		shadow.hide()
		radial_wave.execute_shockwave()
		queue_redraw()

func _draw() -> void:
	if _state == State.TELEGRAPH:
		draw_circle(Vector2.ZERO, radial_wave.max_range, marker_color)
		draw_arc(Vector2.ZERO, radial_wave.max_range, 0.0, TAU, 64, marker_color.lightened(0.35), 2.0)
		return
	if _state == State.IMPACT:
		return
