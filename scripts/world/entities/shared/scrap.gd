extends RigidBody2D

@export var value := 1

var can_collect := false
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	# Connect to detection area
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)

func enable_collection() -> void:
	can_collect = true

func _on_body_entered(body: Node2D):
	if not can_collect:
		return

	if body.is_in_group("player"):
		body.collect_scrap(value)
		queue_free()
