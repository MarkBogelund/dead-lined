extends StaticBody2D
class_name Turret

## Components
@onready var shoot: ShootComponent = $ShootComponent
@onready var vfx_component: VFXComponent = $VFXComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var canon: Node2D = $Canon
@onready var muzzle: Marker2D = $Canon/Graphics/Muzzle

## Targeting
@export var detection_range := 500.0
@export var detection_angle := 0.2 # Radians from aim direction
@export var rotation_speed := 6.0 # Radians per second

## Firing
@export var fire_rate := 0.5 # Seconds between shots
@export var vfx_scene: PackedScene

const UP_FACING_OFFSET := -PI / 2

var _fire_timer := 0.0
var _active := false

func _ready() -> void:
	var wave_manager := get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager:
		wave_manager.combat_phase_started.connect(func(_i): _active = true)
		wave_manager.build_phase_started.connect(func(): _active = false)

func _process(delta: float) -> void:
	if not _active:
		return
	
	_fire_timer -= delta
	
	var target := _find_closest_target()
	if not target:
		return
	
	_rotate_towards(target.global_position, delta)
	
	if _can_fire_at(target):
		_fire_at(target.global_position)

func _find_closest_target() -> Node2D:
	var closest: Node2D = null
	var closest_dist_sq := detection_range * detection_range
	
	for group in ["enemies", "player"]:
		for node in get_tree().get_nodes_in_group(group):
			if node.has_method("is_dead") and node.is_dead():
				continue
			
			var dist_sq := global_position.distance_squared_to(node.global_position)
			if dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				closest = node
	
	return closest

func _rotate_towards(target_pos: Vector2, delta: float) -> void:
	var direction := (target_pos - canon.global_position).angle() + UP_FACING_OFFSET
	canon.rotation = lerp_angle(canon.rotation, direction, rotation_speed * delta)

func _can_fire_at(target: Node2D) -> bool:
	if _fire_timer > 0:
		return false
	
	var target_angle := (target.global_position - canon.global_position).angle() + UP_FACING_OFFSET
	return abs(angle_difference(canon.rotation, target_angle)) < detection_angle

func _fire_at(target_pos: Vector2) -> void:
	if shoot.try_shoot(target_pos, muzzle.global_position):
		_fire_timer = fire_rate
		animation_player.play("recoil")
		if vfx_scene and vfx_component:
			vfx_component.instantiate_vfx(vfx_scene, muzzle.global_position)
