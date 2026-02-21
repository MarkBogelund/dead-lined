extends Area2D
class_name MeleeWeapon

signal slash_started(target_position: Vector2)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var damage := 10
@export var target_knockback := 200.0
@export var slash_radius := 48.0
@export var arc_angle := PI
@export var slash_duration := 0.15
@export var slash_cooldown := 0.3
@export var hit_vfx: PackedScene

var _enabled := true
var _cooldown_timer := 0.0
var _time := 0.0
var _start_angle := 0.0
var _direction := 1
var _slashing := false

func _ready() -> void:
	_reset()
	body_entered.connect(_on_body_entered)

func _reset() -> void:
	_time = 0.0
	_slashing = false
	sprite.visible = false
	monitoring = false
	monitorable = false

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return target_knockback

func set_enabled(enabled: bool) -> void:
	_enabled = enabled

func try_slash(target_pos: Vector2) -> void:
	if _cooldown_timer > 0.0 or not _enabled:
		return
	
	_cooldown_timer = slash_cooldown
	_reset()
	
	# Random swing direction
	_direction = -1 if randf() < 0.5 else 1
	
	# Calculate starting angle
	var dir := (target_pos - global_position).normalized()
	var center_angle := dir.angle()
	_start_angle = center_angle - (_direction * arc_angle * 0.5)
	
	# Activate weapon
	_slashing = true
	sprite.visible = true
	monitoring = true
	monitorable = true
	
	emit_signal("slash_started", target_pos)

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	
	if _slashing:
		_update_slash(delta)

func _update_slash(delta: float) -> void:
	_time += delta
	var t := _time / slash_duration
	
	if t >= 1.0:
		_reset()
		return
	
	# Arc animation
	var angle := _start_angle + (_direction * arc_angle * t)
	rotation = angle + PI / 2
	position = Vector2.RIGHT.rotated(angle) * slash_radius

func _on_body_entered(body: Node2D) -> void:
	if hit_vfx:
		var vfx := hit_vfx.instantiate()
		get_tree().root.add_child(vfx)
		vfx.global_position = body.global_position
