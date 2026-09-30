extends Node

signal device_changed(device: Device)

enum Device {KEYBOARD_MOUSE, CONTROLLER}

@export_group("Right Stick Aim")
@export_range(0.0, 0.95, 0.01) var aim_activation_deadzone := 0.3
@export_range(0.0, 0.95, 0.01) var aim_release_deadzone := 0.2

var active_device := Device.KEYBOARD_MOUSE
var last_aim_direction := Vector2.RIGHT
var _aim_active := false

func _ready() -> void:
	if aim_release_deadzone > aim_activation_deadzone:
		push_error("InputManager aim_release_deadzone must be <= aim_activation_deadzone")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		_set_active_device(Device.KEYBOARD_MOUSE)
	elif event is InputEventJoypadButton:
		_set_active_device(Device.CONTROLLER)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > aim_activation_deadzone:
		_set_active_device(Device.CONTROLLER)

func get_move_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func get_aim_vector() -> Vector2:
	var raw := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.0)
	var deadzone := aim_release_deadzone if _aim_active else aim_activation_deadzone
	if raw.length() <= deadzone:
		_aim_active = false
		return Vector2.ZERO
	_aim_active = true
	last_aim_direction = raw.normalized()
	var strength := inverse_lerp(deadzone, 1.0, minf(raw.length(), 1.0))
	return last_aim_direction * strength

func get_menu_navigation_vector() -> Vector2:
	return Input.get_vector(
		"navigate_menu_left", "navigate_menu_right",
		"navigate_menu_up", "navigate_menu_down")

func get_pointing_direction(mouse_delta: Vector2) -> Vector2:
	if active_device == Device.CONTROLLER:
		return last_aim_direction
	return mouse_delta.normalized() if not mouse_delta.is_zero_approx() else last_aim_direction

func get_pointing_vector(mouse_delta: Vector2, controller_length: float) -> Vector2:
	get_aim_vector()
	if active_device == Device.CONTROLLER:
		return last_aim_direction * controller_length
	return mouse_delta

func get_menu_pointing_vector(mouse_delta: Vector2) -> Vector2:
	return get_menu_navigation_vector() if active_device == Device.CONTROLLER else mouse_delta

func is_controller_active() -> bool:
	return active_device == Device.CONTROLLER

func is_pointer_event(event: InputEvent) -> bool:
	return event is InputEventMouseButton

func is_continuous_attack_active() -> bool:
	return Input.is_action_pressed("attack") \
		or active_device == Device.CONTROLLER and _aim_active

func _set_active_device(value: Device) -> void:
	if active_device == value:
		return
	active_device = value
	device_changed.emit(active_device)