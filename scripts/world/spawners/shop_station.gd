extends StaticBody2D
class_name ShopStation

signal station_opened
signal station_closed

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var shop_manager: ShopManager = $"/root/Game/Systems/ShopManager"

var _enabled := false
var _player_in_range := false

func _ready() -> void:
	shop_manager.shop_system_enabled.connect(_on_shop_system_enabled)
	shop_manager.shop_system_disabled.connect(_on_shop_system_disabled)

	interaction_zone.body_entered.connect(_on_interaction_area_body_entered)
	interaction_zone.body_exited.connect(_on_interaction_area_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or not _player_in_range:
		return
	
	if event.is_action_pressed("open"):
		emit_signal("station_opened")

func _on_shop_system_enabled() -> void:
	_enabled = true
	visible = true
	collision_shape.set_deferred("disabled", false)
	interaction_zone.set_deferred("monitoring", true)

func _on_shop_system_disabled() -> void:
	_enabled = false
	visible = false
	collision_shape.set_deferred("disabled", true)
	interaction_zone.set_deferred("monitoring", false)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		emit_signal("station_closed")
