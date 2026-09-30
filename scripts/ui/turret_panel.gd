extends NinePatchRect
class_name TurretPanel

## Per-turret upgrade panel: level, stats, and upgrade/sell hold buttons. Hovering Upgrade previews the next level.
## Emits requests only; the turret performs upgrades and sales.

signal upgrade_requested
signal upgrade_hold_started(hold_duration: float)
signal upgrade_hold_ended
signal sell_requested
signal close_requested

@export var preview_color := Color(0.45, 1.0, 0.45)

enum Hover {NONE, UPGRADE, SELL}

@onready var health_label: Label = %HealthLabel
@onready var damage_label: Label = %DamageLabel
@onready var speed_label: Label = %SpeedLabel
@onready var range_label: Label = %RangeLabel
@onready var buttons: Control = $"../Buttons"
@onready var upgrade_button: HoldButton = %UpgradeButton
@onready var upgrade_price_row: Control = %UpgradePriceRow
@onready var upgrade_price_label: Label = %UpgradePriceLabel
@onready var upgrade_stack: Control = $"../Buttons/UpgradeStack"
@onready var sell_button: HoldButton = %SellButton
@onready var sell_price_row: Control = %SellPriceRow
@onready var sell_price_label: Label = %SellPriceLabel
@onready var animation_handler: AnimationHandler = $AnimationHandler

var _turret: TurretBase
var _hover := Hover.NONE
var _authored_x: float
var _authored_pivot_x: float

func _ready() -> void:
	_authored_x = position.x
	_authored_pivot_x = pivot_offset.x
	_set_shown(false)
	set_process(false)
	_route_mouse(self)
	_route_mouse(buttons)
	buttons.mouse_filter = Control.MOUSE_FILTER_STOP
	# The outline material is shared with other UI, so each panel gets its own copy.
	material = material.duplicate()
	upgrade_button.hold_completed.connect(upgrade_requested.emit)
	upgrade_button.hold_started.connect(func() -> void: upgrade_hold_started.emit(upgrade_button.hold_duration))
	upgrade_button.hold_ended.connect(upgrade_hold_ended.emit)
	sell_button.hold_completed.connect(sell_requested.emit)
	buttons.gui_input.connect(_gui_input)
	upgrade_button.mouse_entered.connect(_set_hover.bind(Hover.UPGRADE))
	upgrade_button.mouse_exited.connect(_clear_hover.bind(Hover.UPGRADE))
	sell_button.mouse_entered.connect(_set_hover.bind(Hover.SELL))
	sell_button.mouse_exited.connect(_clear_hover.bind(Hover.SELL))
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
	_set_shown(true)
	set_process(true)
	(upgrade_button if upgrade_stack.visible else sell_button).grab_focus()
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
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("start_color", start_color)
	shader_material.set_shader_parameter("end_color", end_color)
## Mirrors the scene-authored placement around the turret (x = 0) when it would leave the screen.
func flip_if_offscreen(turret_screen_x: float) -> void:
	var left := turret_screen_x + _authored_x
	var flipped := left < 0.0 or left + size.x > get_viewport_rect().size.x
	position.x = - _authored_x - size.x if flipped else _authored_x
	pivot_offset.x = size.x - _authored_pivot_x if flipped else _authored_pivot_x
func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if not mouse_button or not mouse_button.pressed:
		return
	accept_event()
	if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
		close_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("navigate_menu_left") or event.is_action_pressed("navigate_menu_up"):
		if upgrade_stack.visible:
			upgrade_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("navigate_menu_right") or event.is_action_pressed("navigate_menu_down"):
		sell_button.grab_focus()
		get_viewport().set_input_as_handled()

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
	if InputManager.is_controller_active():
		if upgrade_stack.visible and upgrade_button.has_focus():
			_set_hover(Hover.UPGRADE)
		elif sell_button.has_focus():
			_set_hover(Hover.SELL)
		else:
			_set_hover(Hover.NONE)
		return
	var mouse_position := get_global_mouse_position()
	if upgrade_stack.visible and upgrade_button.get_global_rect().has_point(mouse_position):
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
	upgrade_stack.visible = not maxed
	if not maxed:
		upgrade_button.disabled = not _turret.can_upgrade()
	sell_button.disabled = not _turret.can_sell()
	upgrade_price_label.text = "%d" % int(_turret.get_upgrade_cost())
	sell_price_label.text = "%d" % int(_turret.get_sell_value())

func _set_stat(label: Label, current_value: String, preview_value: String) -> void:
	var changed := not preview_value.is_empty() and preview_value != current_value
	label.text = preview_value if changed else current_value
	label.self_modulate = preview_color if changed else Color.WHITE

func _format_cooldown(seconds: float) -> String:
	return "%ss" % snappedf(seconds, 0.01)

## The root catches clicks on the panel; buttons pass unhandled ones (e.g. right click) up to it.
func _route_mouse(node: Node) -> void:
	for child in node.get_children():
		var control := child as Control
		if control:
			control.mouse_filter = Control.MOUSE_FILTER_PASS if control is BaseButton else Control.MOUSE_FILTER_IGNORE
		_route_mouse(child)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"disappear":
		_set_shown(false)

## Buttons is a sibling so it can be placed independently, but it opens and closes with the panel.
func _set_shown(value: bool) -> void:
	visible = value
	buttons.visible = value
