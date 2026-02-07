extends Control
class_name TurretShopUI

signal turret_selected(turret_scene: PackedScene)

@export var turret_scene: PackedScene

func _ready() -> void:
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _on_select_button_pressed() -> void:
	if turret_scene == null:
		push_error("TurretShopUI: turret_scene not assigned")
		return

	emit_signal("turret_selected", turret_scene)
