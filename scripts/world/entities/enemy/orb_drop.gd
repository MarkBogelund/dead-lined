extends Node
class_name OrbDropComponent

## Spawns capacity orbs and, by chance, a Crunch Time powerup where its entity dies.

@export var orb_scene: PackedScene
@export var crunch_powerup_scene: PackedScene
@export var impulse_min := 100.0
@export var impulse_max := 300.0
## How quickly dropped orbs slow down (higher = stops faster).
@export var linear_damp := 3.0

var orb_drop_amount := 1
var crunch_powerup_chance := 0.0
var _parent: Node2D

func initialize(p_orb_drop_amount: int, p_crunch_powerup_chance: float) -> void:
	orb_drop_amount = p_orb_drop_amount
	crunch_powerup_chance = p_crunch_powerup_chance

func _ready() -> void:
	_parent = get_parent() as Node2D
	if not _parent:
		push_error("OrbDropComponent must be a child of a Node2D entity")
	if not orb_scene or not crunch_powerup_scene:
		push_error("OrbDropComponent requires orb_scene and crunch_powerup_scene")

## Called from each enemy's die animation.
func drop() -> void:
	if not _parent or not orb_scene or not crunch_powerup_scene:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.crunch_time.is_crunch_time_active():
		return
	for i: int in range(orb_drop_amount):
		_spawn(orb_scene)
	if randf() < crunch_powerup_chance:
		_spawn(crunch_powerup_scene)

func _spawn(scene: PackedScene) -> void:
	var orb := scene.instantiate() as Orb
	orb.linear_damp = linear_damp
	get_tree().current_scene.add_child(orb)
	orb.global_position = _parent.global_position
	orb.launch(Vector2.from_angle(randf() * TAU) * randf_range(impulse_min, impulse_max))
