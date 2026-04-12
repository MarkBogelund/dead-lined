extends RigidBody2D

@export var value := 1

var can_collect := false
@onready var detection_area: Area2D = $DetectionArea
@onready var animation_handler: AnimationHandler = $AnimationHandler

func _ready():
	add_to_group("scrap")
	detection_area.body_entered.connect(_on_body_entered)
	animation_handler.configure_animation("pick_up", 1, true)
	animation_handler.configure_animation("idle", 0, false)

func enable_collection() -> void:
	can_collect = true

func _on_body_entered(body: Node2D):
	if not can_collect:
		return

	if body.is_in_group("player"):
		var crunch_time: CrunchTimeComponent = body.get_node_or_null("CrunchTimeComponent")
		if crunch_time and crunch_time.is_active:
			return
		body.collect_scrap(value)
		animation_handler.play_animation("pick_up")
