extends Control
class_name TurretInfoPanel

## Center panel of the radial shop: shows the highlighted turret's name, price and stats.

const COLOR_UNAVAILABLE := Color(0.6, 0.6, 0.6, 1.0)

@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel
@onready var health_label: Label = %HealthLabel
@onready var damage_label: Label = %DamageLabel
@onready var speed_label: Label = %SpeedLabel
@onready var limit_label: Label = %LimitLabel
@onready var content: Control = %Content
@onready var animation_handler: AnimationHandler = $AnimationHandler

func _ready() -> void:
	animation_handler.configure_animation("refresh", 0, false)

func show_entry(entry: TurretEntry, can_afford: bool, limit_reached: bool) -> void:
	name_label.text = entry.name
	price_label.text = str(entry.price)
	health_label.text = str(entry.stats.max_health)
	damage_label.text = str(entry.stats.damage)
	speed_label.text = "%ss" % snappedf(entry.stats.attack_cooldown, 0.01)
	price_label.self_modulate = Color.WHITE if can_afford else Color.RED
	content.modulate = Color.WHITE if can_afford and not limit_reached else COLOR_UNAVAILABLE
	limit_label.visible = limit_reached
	animation_handler.restart_animation("refresh")
