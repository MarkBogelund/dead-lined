extends Control
class_name ShopPanel

signal turret_selected(turret_entry: TurretEntry)

@export var _slots: Array[TurretSlot] = []
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false
	add_to_group("shop_panel")

func open(entries: Array[TurretEntry], can_afford_fn: Callable) -> void:
	for i in _slots.size():
		var slot := _slots[i]
		if i < entries.size():
			var entry := entries[i]
			slot.visible = true
			slot.populate(entry, can_afford_fn.call(entry.price))
			for conn in slot.selected.get_connections():
				slot.selected.disconnect(conn.callable)
			slot.selected.connect(func(): turret_selected.emit(entry))
		else:
			slot.visible = false
	visible = true
	animation_player.play(&"appear")

func close() -> void:
	animation_player.play(&"disappear")
	await animation_player.animation_finished
	visible = false
