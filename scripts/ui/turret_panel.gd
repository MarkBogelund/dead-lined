extends Control
class_name TurretPanel

## Per-turret upgrade panel: level, stats, and upgrade/sell hold buttons. Hovering Upgrade previews the next level.
## Emits requests only; the turret performs upgrades and sales.

signal upgrade_requested
signal upgrade_hold_started(hold_duration: float)
signal upgrade_hold_ended
signal sell_requested
signal close_requested

## Price row color while hovering Upgrade (orbs spent) and Sell (orbs gained).
@export var cost_color := Color(1.0, 0.35, 0.35)
@export var refund_color := Color(0.45, 1.0, 0.45)
@export var preview_color := Color(0.45, 1.0, 0.45)

enum Hover {NONE, UPGRADE, SELL}

@onready var health_label: Label = %HealthLabel
@onready var damage_label: Label = %DamageLabel
@onready var speed_label: Label = %SpeedLabel
@onready var range_label: Label = %RangeLabel
@onready var actions: Control = $"../Actions"
@onready var upgrade_button: HoldButton = %UpgradeButton
@onready var upgrade_price_row: Control = %UpgradePriceRow
@onready var upgrade_price_label: Label = %UpgradePriceLabel
@onready var max_label: Label = %MaxLabel
@onready var sell_button: HoldButton = %SellButton
@onready var sell_price_row: Control = %SellPriceRow
@onready var sell_price_label: Label = %SellPriceLabel
@onready var animation_handler: AnimationHandler = $AnimationHandler
@onready var _outlines: Array[CanvasItem] = [%PanelOutline]

var _turret: TurretBase
var _hover := Hover.NONE

func _ready() -> void:
	visible = false
	set_process(false)
	_route_mouse(self)
	_route_mouse(actions)
	# The outline material is shared with other UI, so each panel gets its own copy.
	for outline in _outlines:
		outline.material = outline.material.duplicate()
	upgrade_button.hold_completed.connect(upgrade_requested.emit)
	upgrade_button.hold_started.connect(func() -> void: upgrade_hold_started.emit(upgrade_button.hold_duration))
	upgrade_button.hold_ended.connect(upgrade_hold_ended.emit)
	sell_button.hold_completed.connect(sell_requested.emit)
	actions.gui_input.connect(_gui_input)
	upgrade_button.mouse_entered.connect(_set_hover.bind(Hover.UPGRADE))
	upgrade_button.mouse_exited.connect(_clear_hover.bind(Hover.UPGRADE))
	upgrade_button.focus_entered.connect(_set_hover.bind(Hover.UPGRADE))
	upgrade_button.focus_exited.connect(_clear_hover.bind(Hover.UPGRADE))
	sell_button.mouse_entered.connect(_set_hover.bind(Hover.SELL))
	sell_button.mouse_exited.connect(_clear_hover.bind(Hover.SELL))
	sell_button.focus_entered.connect(_set_hover.bind(Hover.SELL))
	sell_button.focus_exited.connect(_clear_hover.bind(Hover.SELL))
	animation_handler.configure_animation("appear", 0, false)
	animation_handler.configure_animation("disappear", 1, false)
	animation_handler.configure_animation("upgrade_hover", 2, false)
	animation_handler.configure_animation("upgrade_idle", 1, false)
	animation_handler.configure_animation("sell_hover", 2, false)
	animation_handler.configure_animation("sell_idle", 1, false)
	animation_handler.animation_finished.connect(_on_animation_finished)

func _process(_delta: float) -> void:
	_update_pointer_hover()
	_refresh()

func open(turret: TurretBase) -> void:
	_turret = turret
	_refresh()
	visible = true
	set_process(true)
	animation_handler.play_animation("appear")

func close() -> void:
	if _hover == Hover.UPGRADE:
		animation_handler.play_animation("upgrade_idle")
	elif _hover == Hover.SELL:
		animation_handler.play_animation("sell_idle")
	_hover = Hover.NONE
	set_process(false)
	animation_handler.play_animation("disappear")

func set_outline_colors(start_color: Color, end_color: Color) -> void:
	for outline in _outlines:
		var shader_material := outline.material as ShaderMaterial
		shader_material.set_shader_parameter("start_color", start_color)
		shader_material.set_shader_parameter("end_color", end_color)

func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if not mouse_button or not mouse_button.pressed:
		return
	accept_event()
	if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
		close_requested.emit()

func _set_hover(value: Hover) -> void:
	if _hover == value:
		return
	var previous_hover := _hover
	_hover = value
	match value:
		Hover.UPGRADE:
			animation_handler.play_animation("upgrade_hover")
		Hover.SELL:
			animation_handler.play_animation("sell_hover")
		Hover.NONE:
			if previous_hover == Hover.UPGRADE:
				animation_handler.play_animation("upgrade_idle")
			elif previous_hover == Hover.SELL:
				animation_handler.play_animation("sell_idle")

func _update_pointer_hover() -> void:
	if upgrade_button.has_focus():
		_set_hover(Hover.UPGRADE)
		return
	if sell_button.has_focus():
		_set_hover(Hover.SELL)
		return
	var mouse_position := get_global_mouse_position()
	if upgrade_button.get_global_rect().has_point(mouse_position):
		_set_hover(Hover.UPGRADE)
	elif sell_button.get_global_rect().has_point(mouse_position):
		_set_hover(Hover.SELL)
	else:
		_set_hover(Hover.NONE)

## Ignores exits from a button that is no longer the hovered one.
func _clear_hover(value: Hover) -> void:
	if _hover == value:
		_set_hover(Hover.NONE)

func _refresh() -> void:
	var maxed := _turret.is_max_level()
	var preview := _turret.get_next_level_stats() if _hover == Hover.UPGRADE and not maxed else null
	var current_stats := _turret.get_stat_values()
	_set_stat(health_label, str(current_stats.max_health), str(preview.max_health) if preview else "")
	_set_stat(damage_label, str(current_stats.damage), str(preview.damage) if preview else "")
	_set_stat(speed_label, _format_cooldown(current_stats.attack_cooldown), _format_cooldown(preview.attack_cooldown) if preview else "")
	_set_stat(range_label, str(roundi(current_stats.attack_range)), str(roundi(preview.attack_range)) if preview else "")
	upgrade_button.visible = not maxed
	max_label.visible = maxed
	if not maxed:
		upgrade_button.disabled = not _turret.can_upgrade()
	sell_button.disabled = not _turret.can_sell()
	_refresh_prices(maxed)

func _set_stat(label: Label, current_value: String, preview_value: String) -> void:
	var changed := not preview_value.is_empty() and preview_value != current_value
	label.text = preview_value if changed else current_value
	label.self_modulate = preview_color if changed else Color.WHITE

func _format_cooldown(seconds: float) -> String:
	return "%ss" % snappedf(seconds, 0.01)

func _refresh_prices(maxed: bool) -> void:
	if _hover == Hover.UPGRADE and not maxed:
		upgrade_price_label.text = "%d" % int(_turret.get_upgrade_cost())
		upgrade_price_label.self_modulate = cost_color
	if _hover == Hover.SELL:
		sell_price_label.text = "%d" % int(_turret.get_sell_value())
		sell_price_label.self_modulate = refund_color

## The root catches clicks on the panel; buttons pass unhandled ones (e.g. right click) up to it.
func _route_mouse(node: Node) -> void:
	for child in node.get_children():
		var control := child as Control
		if control:
			control.mouse_filter = Control.MOUSE_FILTER_PASS if control is BaseButton else Control.MOUSE_FILTER_IGNORE
		_route_mouse(child)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"disappear":
		visible = false
