extends StaticBody2D
class_name ShopStation

signal station_opened
signal station_closed

@onready var shop_manager: ShopManager = %ShopManager
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_zone: InteractionZone = $InteractionZone
@onready var animation_handler: AnimationHandler = $AnimationHandler

var _enabled := false

func _ready() -> void:
	shop_manager.shop_system_enabled.connect(_on_shop_system_enabled)
	shop_manager.shop_system_disabled.connect(_on_shop_system_disabled)

	interaction_zone.player_entered.connect(_on_player_entered)
	interaction_zone.player_exited.connect(_on_player_exited)

	animation_handler.configure_animation("rest", 0, false)
	animation_handler.configure_animation("hover", 1, false)
	animation_handler.configure_animation("appear", 2, true)
	animation_handler.configure_animation("dissapear", 3, true)

func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or not interaction_zone.is_player_in_range():
		return
	
	if event.is_action_pressed("open"):
		emit_signal("station_opened")

func _on_shop_system_enabled() -> void:
	_enabled = true
	animation_handler.play_animation("appear")

func _on_shop_system_disabled() -> void:
	_enabled = false
	animation_handler.play_animation("dissapear")

func _on_player_entered() -> void:
	animation_handler.play_animation("hover")

func _on_player_exited() -> void:
	emit_signal("station_closed")
	animation_handler.play_animation("rest")
