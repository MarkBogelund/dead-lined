extends StaticBody2D
class_name ShopStation

@onready var shop_manager: ShopManager = %ShopManager
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_zone: InteractionZone = $InteractionZone
@onready var animation_handler: AnimationHandler = $AnimationHandler
@onready var toggle_menu: ToggleMenuComponent = $ToggleMenuComponent


func _ready() -> void:
	shop_manager.shop_system_enabled.connect(_on_shop_system_enabled)
	shop_manager.shop_system_disabled.connect(_on_shop_system_disabled)

	interaction_zone.player_entered.connect(_on_player_entered)
	interaction_zone.player_exited.connect(_on_player_exited)

	toggle_menu.interaction_zone = interaction_zone

	animation_handler.configure_animation("rest", 0, false)
	animation_handler.configure_animation("hover", 1, false)
	animation_handler.configure_animation("appear", 2, true)
	animation_handler.configure_animation("dissapear", 3, true)


func _on_shop_system_enabled() -> void:
	toggle_menu.enabled = true
	animation_handler.play_animation("appear")


func _on_shop_system_disabled() -> void:
	toggle_menu.enabled = false
	animation_handler.play_animation("dissapear")


func _on_player_entered() -> void:
	animation_handler.play_animation("hover")


func _on_player_exited() -> void:
	animation_handler.play_animation("rest")
