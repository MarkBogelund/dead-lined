extends TurretBase

@onready var vfx_component: VFXComponent = $VFXComponent
@export var vfx_scene: PackedScene

@onready var canon: Node2D = $Canon
@onready var muzzle: Marker2D = $Canon/Graphics/Muzzle
@onready var shoot: ShootComponent = $ShootComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var detection_angle := 0.2           # radians
@export var rotation_speed := 6.0            # radians per second
@export var fire_rate := 0.5                 # seconds per shot
var fire_timer := 0.0

const UP_FACING_OFFSET := -PI / 2

func _process(delta):
	if build_phase:
		return

	fire_timer -= delta

	var target := get_closest_enemy_in_range()
	if target == null:
		return

	rotate_towards(target.global_position, delta)

	if can_fire_at(target):
		animation_player.play("recoil")
		shoot.shoot(target.global_position, muzzle.global_position)
		vfx_component.instantiate_vfx(vfx_scene, muzzle.global_position)
		fire_timer = fire_rate

func rotate_towards(target_pos: Vector2, delta: float):
	var dir := target_pos - canon.global_position
	var target_angle := dir.angle() + UP_FACING_OFFSET

	canon.rotation = lerp_angle(
		canon.rotation,
		target_angle,
		rotation_speed * delta
	)

func can_fire_at(target: Node2D) -> bool:
	if fire_timer > 0:
		return false

	var dir := target.global_position - canon.global_position
	var target_angle := dir.angle() + UP_FACING_OFFSET

	return abs(angle_difference(canon.rotation, target_angle)) < detection_angle
