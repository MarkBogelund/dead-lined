extends Control
class_name ShopPanel

## Radial turret shop. Cards circle the info panel; the mouse direction from the screen center picks the highlighted card.

signal turret_selected(turret_entry: TurretEntry)
signal close_requested

@export var card_scene: PackedScene
## Distance in pixels from the center to each card.
@export var radius := 80.0
## Direction of the first card in degrees (0 = right, -90 = up); the rest follow clockwise.
@export var start_angle_degrees := -90.0
## The highlight is kept while the mouse is closer than this to the center.
@export var dead_zone_radius := 40.0

@onready var content: Control = $Content
@onready var cards_root: Control = %Cards
@onready var info_panel: TurretInfoPanel = %TurretInfoPanel
@onready var animation_handler: AnimationHandler = $AnimationHandler

var _entries: Array[TurretEntry] = []
var _cards: Array[TurretCard] = []
var _can_afford_fn: Callable
var _limit_reached := false
var _highlighted := -1
var _is_open := false
var _using_controller := false

func _ready() -> void:
	visible = false
	add_to_group("shop_panel")
	set_process(false)
	if not card_scene:
		push_error("ShopPanel requires card_scene")
	_ignore_mouse(content)
	animation_handler.configure_animation("appear", 0, false)
	animation_handler.configure_animation("disappear", 1, false)
	animation_handler.animation_finished.connect(_on_animation_finished)

func open(entries: Array[TurretEntry], can_afford_fn: Callable, limit_reached: bool) -> void:
	_entries = entries
	_can_afford_fn = can_afford_fn
	_limit_reached = limit_reached
	_build_cards()
	_is_open = true
	visible = true
	set_process(true)
	animation_handler.play_animation("appear")
	if not _cards.is_empty():
		_set_highlighted(maxi(_sector_under_input(), 0))

func close() -> void:
	_is_open = false
	set_process(false)
	animation_handler.play_animation("disappear")

func _process(_delta: float) -> void:
	var sector := _sector_under_input()
	if sector >= 0:
		_set_highlighted(sector)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_using_controller = false
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_using_controller = true
	if not _is_open or not event is InputEventJoypadButton:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_select_highlighted()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()

func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if not _is_open or not mouse_button or not mouse_button.pressed:
		return
	if mouse_button.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_select_highlighted()
	elif mouse_button.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		close_requested.emit()

func _build_cards() -> void:
	for card in _cards:
		cards_root.remove_child(card)
		card.queue_free()
	_cards.clear()
	_highlighted = -1
	for i in _entries.size():
		var card := card_scene.instantiate() as TurretCard
		_ignore_mouse(card)
		cards_root.add_child(card)
		var direction := Vector2.from_angle(_card_angle(i))
		card.position = direction * radius
		card.populate(_entries[i], _is_available(_entries[i]), direction)
		_cards.append(card)

## -1 inside the dead zone, otherwise the card closest to the active pointer direction.
func _sector_under_input() -> int:
	if _cards.is_empty():
		return -1
	var direction := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down") \
		if _using_controller else get_global_mouse_position() - content.global_position
	var minimum_length := 0.0 if _using_controller else dead_zone_radius
	if direction.length() <= minimum_length:
		return -1
	var step := TAU / _cards.size()
	return posmod(roundi((direction.angle() - deg_to_rad(start_angle_degrees)) / step), _cards.size())

func _card_angle(index: int) -> float:
	return deg_to_rad(start_angle_degrees) + index * TAU / _entries.size()

func _set_highlighted(index: int) -> void:
	if index == _highlighted:
		return
	if _highlighted >= 0:
		_cards[_highlighted].set_highlighted(false)
	_highlighted = index
	_cards[index].set_highlighted(true)
	var entry := _entries[index]
	info_panel.show_entry(entry, _can_afford_fn.call(entry.price), _limit_reached)

func _select_highlighted() -> void:
	if _highlighted < 0:
		return
	var entry := _entries[_highlighted]
	if not _is_available(entry):
		_cards[_highlighted].reject()
		return
	turret_selected.emit(entry)

func _is_available(entry: TurretEntry) -> bool:
	return not _limit_reached and _can_afford_fn.call(entry.price)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"disappear":
		visible = false

## Every click must reach this root's _gui_input, however the card and info panel layouts are built.
func _ignore_mouse(node: Node) -> void:
	var control := node as Control
	if control:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
