extends Node
class_name ToggleMenuComponent

## Self-contained menu toggle component.
## Attach as a child of any entity that drives a menu.
## Set open_fn / close_fn from the owning system to drive the actual menu.

signal opened
signal closed

@export_group("Open Triggers")
@export var open_on_proximity: bool = false
@export var open_on_proximity_and_button: bool = false
@export var open_on_button: bool = false
@export var open_action: StringName = &"open"

@export_group("Close Triggers")
@export var close_on_exit_proximity: bool = false
@export var close_on_toggle_button: bool = false
@export var close_on_cancel: bool = false
@export var close_on_click_away: bool = false
@export var close_on_combat_phase: bool = false
@export var cancel_action: StringName = &"cancel"

## Area2D with InteractionZone script — used for proximity detection.
var interaction_zone: InteractionZone:
	set(value):
		_disconnect_interaction_zone()
		interaction_zone = value
		if is_node_ready():
			_connect_interaction_zone()

## Root Control of the menu — used for click-away hit testing.
var menu_control: Control

## Set to false to block all triggers (e.g. during combat phase).
var enabled: bool = true

## Callables set by the owning system to drive the actual menu.
var open_fn: Callable
var close_fn: Callable

var is_open: bool = false

const PROXIMITY_BUTTON_GROUP := &"proximity_button_menus"
const INPUT_BLOCKING_GROUP := &"open_input_blocking_menus"


func _ready() -> void:
	_connect_interaction_zone()
	if open_on_proximity_and_button:
		add_to_group(PROXIMITY_BUTTON_GROUP)
	if close_on_combat_phase:
		var wave_manager := get_tree().get_first_node_in_group("wave_manager") as WaveManager
		if wave_manager:
			wave_manager.combat_phase_started.connect(func(_i: int) -> void:
				close()
				enabled = false
			)
			wave_manager.build_phase_started.connect(func() -> void:
				enabled = true
			)


func open() -> void:
	if is_open:
		return
	is_open = true
	add_to_group(INPUT_BLOCKING_GROUP)
	if open_fn.is_valid():
		open_fn.call()
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	remove_from_group(INPUT_BLOCKING_GROUP)
	if close_fn.is_valid():
		close_fn.call()
	closed.emit()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if is_open:
		_handle_close_triggers(event)
	else:
		_handle_open_triggers(event)


func _handle_open_triggers(event: InputEvent) -> void:
	if open_on_button and event.is_action_pressed(open_action):
		open()
		get_viewport().set_input_as_handled()
		return
	if open_on_proximity_and_button and event.is_action_pressed(open_action):
		if _wins_proximity_open():
			open()
			get_viewport().set_input_as_handled()

## With several proximity menus in range, only the one nearest the player opens; an open one must close first.
func _wins_proximity_open() -> bool:
	if not interaction_zone or not interaction_zone.is_player_in_range():
		return false
	var player := interaction_zone.get_player()
	var own_distance := player.global_position.distance_squared_to(interaction_zone.global_position)
	for node in get_tree().get_nodes_in_group(PROXIMITY_BUTTON_GROUP):
		var other := node as ToggleMenuComponent
		if other == self or not other.enabled or not other.interaction_zone:
			continue
		if other.is_open:
			return false
		if other.interaction_zone.is_player_in_range() \
				and player.global_position.distance_squared_to(other.interaction_zone.global_position) < own_distance:
			return false
	return true


func _handle_close_triggers(event: InputEvent) -> void:
	if close_on_toggle_button and event.is_action_pressed(open_action):
		close()
		get_viewport().set_input_as_handled()
		return
	if close_on_cancel and event.is_action_pressed(cancel_action):
		close()
		get_viewport().set_input_as_handled()
		return
	if close_on_click_away and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if menu_control and not menu_control.get_global_rect().has_point(mb.global_position):
				close()
				get_viewport().set_input_as_handled()


func _on_player_entered() -> void:
	if not enabled:
		return
	open()


func _on_player_exited() -> void:
	if close_on_exit_proximity and is_open:
		close()


func _connect_interaction_zone() -> void:
	if not interaction_zone:
		return
	if open_on_proximity:
		if not interaction_zone.player_entered.is_connected(_on_player_entered):
			interaction_zone.player_entered.connect(_on_player_entered)
	if close_on_exit_proximity:
		if not interaction_zone.player_exited.is_connected(_on_player_exited):
			interaction_zone.player_exited.connect(_on_player_exited)


func _disconnect_interaction_zone() -> void:
	if not interaction_zone:
		return
	if interaction_zone.player_entered.is_connected(_on_player_entered):
		interaction_zone.player_entered.disconnect(_on_player_entered)
	if interaction_zone.player_exited.is_connected(_on_player_exited):
		interaction_zone.player_exited.disconnect(_on_player_exited)
