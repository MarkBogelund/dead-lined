extends Node
class_name ToggleMenuComponent

## Attach as a child of any entity that triggers a menu.
## Handles proximity and input triggers; delegates all state to MenuManager.
## Works for both static stations (shop) and dynamic entities (turrets).

@export_group("Menu")
## Must match the id used when registering with MenuManager.
@export var menu_id: StringName

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
@export var cancel_action: StringName = &"cancel"

@export_group("References")
## Area2D with InteractionZone script — used for proximity detection.
## Supports being set either from the scene file or programmatically after _ready.
@export var interaction_zone: InteractionZone:
	set(value):
		_disconnect_interaction_zone()
		interaction_zone = value
		if is_node_ready():
			_connect_interaction_zone()
## Root Control of the menu — used for click-away hit testing.
@export var menu_control: Control
## Passed as context to MenuManager.request_open (e.g. which turret to show).
## Defaults to get_parent() if not set.
@export var context_node: Node

## Set to false to block all triggers (e.g. during combat phase).
var enabled: bool = true


func _ready() -> void:
	_connect_interaction_zone()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if MenuManager.is_open(menu_id):
		_handle_close_triggers(event)
	else:
		_handle_open_triggers(event)


func _handle_open_triggers(event: InputEvent) -> void:
	if open_on_button and event.is_action_pressed(open_action):
		_request_open()
		get_viewport().set_input_as_handled()
		return
	if open_on_proximity_and_button and event.is_action_pressed(open_action):
		if interaction_zone and interaction_zone.is_player_in_range():
			_request_open()
			get_viewport().set_input_as_handled()


func _handle_close_triggers(event: InputEvent) -> void:
	if close_on_toggle_button and event.is_action_pressed(open_action):
		MenuManager.request_close(menu_id)
		get_viewport().set_input_as_handled()
		return
	if close_on_cancel and event.is_action_pressed(cancel_action):
		MenuManager.request_close(menu_id)
		get_viewport().set_input_as_handled()
		return
	if close_on_click_away and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if menu_control and not menu_control.get_global_rect().has_point(mb.global_position):
				MenuManager.request_close(menu_id)
				get_viewport().set_input_as_handled()


func _on_player_entered() -> void:
	if not enabled:
		return
	_request_open()


func _on_player_exited() -> void:
	if close_on_exit_proximity and MenuManager.is_open(menu_id):
		MenuManager.request_close(menu_id)


func _request_open() -> void:
	var ctx: Node = context_node if context_node else get_parent()
	MenuManager.request_open(menu_id, ctx)


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
