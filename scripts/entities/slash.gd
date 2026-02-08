extends Node2D
class_name Slash

var player

# --- Weapon ---
@onready var weapon: Sprite2D = $Weapon
@onready var hitbox: Area2D = $Weapon/Hitbox

@export var damage := 10
@export var target_knockback := 100
@export var player_knockback := 200.0
@export var slash_radius := 48.0
@export var arc_angle := PI
@export var slash_duration := 0.15

var _time := 0.0
var _start_angle := 0.0
var _direction := 1

# --- Smear / Trail ---
@onready var trail: Line2D = $Trail

@onready var trail_shader: ShaderMaterial = $Trail.material as ShaderMaterial
@export var shrink_speed := 2.0

# --- Trail emission configuration ---
@export var trail_offset := 0.0     # along the weapon axis (0=center, +forward, -back)
@export var trail_behind := -10.0   # extra offset to emit behind the weapon
@export var trail_length := 12       # Number of points in the trail

var _elapsed := 0.0
var _retracting := false

@export var hit_vfx: PackedScene

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_reset_weapon()
	_reset_smear()

func _disable_weapon():
	weapon.visible = false
	hitbox.monitorable = false
	hitbox.monitoring = false

func _enable_weapon():
	weapon.visible = true
	hitbox.monitorable = true
	hitbox.monitoring = true

func _reset_weapon():
	_time = 0.0
	_disable_weapon()

func _reset_smear():
	trail.visible = false
	trail.clear_points()
	_elapsed = 0.0
	_retracting = false
	trail_shader.set_shader_parameter("elapsed", 0.0)
	trail_shader.set_shader_parameter("shrink_speed", shrink_speed)

func start_slash(mouse_global_pos: Vector2) -> void:
	_reset_weapon()
	_reset_smear()

	_direction = -1 if randf() < 0.5 else 1

	var dir := (mouse_global_pos - global_position).normalized()
	var center_angle := dir.angle()
	_start_angle = center_angle - (_direction * arc_angle * 0.5)

	_enable_weapon()
	trail.visible = true
	set_process(true)
	
	player.apply_knockback(mouse_global_pos, player_knockback)

func _process(delta: float) -> void:
	if not _retracting:
		_update_weapon(delta)
	else:
		_update_smear(delta)

func _update_weapon(delta: float) -> void:
	_time += delta
	var t := _time / slash_duration
	if t >= 1.0:
		_disable_weapon()
		_retracting = true
		return

	var angle := _start_angle + (_direction * arc_angle * t)
	weapon.rotation = angle + PI / 2
	weapon.position = Vector2.RIGHT.rotated(angle) * slash_radius

	_add_tip_to_trail()

func _add_tip_to_trail() -> void:
	# Offset along the weapon axis (tip/center)
	var along_vector = Vector2(trail_offset, 0).rotated(weapon.rotation - PI / 2)
	
	# Trail behind (orthogonal to weapon axis and aware of direction)
	var perp_vector = Vector2(0, trail_behind * _direction * -1).rotated(weapon.rotation - PI / 2)
	
	var total_offset = along_vector + perp_vector
	var tip_local = (weapon.global_position + total_offset) - trail.global_position
	trail.add_point(tip_local)
	
	while trail.get_point_count() > trail_length:
		trail.remove_point(0)

func _update_smear(delta: float) -> void:
	_elapsed += delta
	trail_shader.set_shader_parameter("elapsed", _elapsed)

	if _elapsed * shrink_speed >= 1.0:
		trail.visible = false
		trail.clear_points()
		set_process(false)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

		if body.has_method("apply_knockback"):
			body.apply_knockback(weapon.global_position, target_knockback)
			
	add_hit_vfx(body.position)

func add_hit_vfx(hit_position: Vector2):
	if hit_vfx == null:
		push_error("No hit vfx scene attached")
		return
	
	var hit = hit_vfx.instantiate()
	hit.position = hit_position
	get_tree().current_scene.add_child(hit)
