extends Node2D
class_name SlashComponent

signal slash_started(target_position: Vector2)

@onready var vfx_component: VFXComponent = $"../VFXComponent"
@export var hit_vfx: PackedScene
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

@export var slashing_activated := true

# --- Weapon ---
@onready var weapon: Sprite2D = $Weapon
@onready var hitbox: HitboxComponent = $Weapon/Hitbox

@export var damage := 10
@export var target_knockback := 200
@export var player_knockback := 100.0
@export var slash_radius := 48.0
@export var arc_angle := PI
@export var slash_duration := 0.15

@export var slash_cooldown := 0.3
var _cooldown_timer := 0.0

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return target_knockback

var _time := 0.0
var _start_angle := 0.0
var _direction := 1

# --- Smear / Trail ---
@onready var trail: Line2D = $Trail
@onready var trail_shader: ShaderMaterial = $Trail.material as ShaderMaterial
@export var shrink_speed := 2.0

# --- Trail emission configuration ---
@export var trail_offset := 0.0 # along the weapon axis (0=center, +forward, -back)
@export var trail_behind := -10.0 # perpendicular offset from weapon
@export var trail_length := 12 # Number of points in the trail

var _elapsed := 0.0
var _retracting := false

func _ready():
	_reset_weapon()
	_reset_smear()
	set_process(true)

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

func set_enabled(enabled: bool):
	slashing_activated = enabled

func try_slash(mouse_global_pos: Vector2) -> void:
	if _cooldown_timer > 0.0 or not slashing_activated:
		return

	_cooldown_timer = slash_cooldown
	
	_reset_weapon()
	_reset_smear()

	_direction = -1 if randf() < 0.5 else 1

	var dir := (mouse_global_pos - global_position).normalized()
	var center_angle := dir.angle()
	_start_angle = center_angle - (_direction * arc_angle * 0.5)

	_enable_weapon()
	trail.visible = true

	emit_signal("slash_started", mouse_global_pos)

func _process(delta: float) -> void:
	# Cooldown timer always counts down
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	if not _retracting and weapon.visible:
		_update_weapon(delta)
	elif trail.visible:
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
	
	# Perpendicular offset from weapon
	var perp_vector = Vector2(0, trail_behind).rotated(weapon.rotation - PI / 2)
	
	var total_offset = along_vector + perp_vector
	var tip_local = (weapon.global_position + total_offset) - trail.global_position
	trail.add_point(tip_local)
	
	# Keep only the last 'trail_length' points
	while trail.get_point_count() > trail_length:
		trail.remove_point(0)

func _update_smear(delta: float) -> void:
	_elapsed += delta
	trail_shader.set_shader_parameter("elapsed", _elapsed)

	if _elapsed * shrink_speed >= 1.0:
		trail.visible = false
		trail.clear_points()
		_retracting = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	vfx_component.instantiate_vfx(hit_vfx, body.global_position)
