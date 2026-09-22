extends AnimationPlayer
class_name AnimationHandler

## Generic animation handler with priority and locking system
## Can be used by any entity with animations

signal animation_locked
signal animation_unlocked

var _animations := {} # {anim_name: {priority: int, locks: bool}}
var _current_animation := ""
var _current_priority := 0
var _locked := false

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)

## Configure an animation with priority and locking behavior
func configure_animation(anim_name: String, priority: int, locks: bool) -> void:
	_animations[anim_name] = {
		"priority": priority,
		"locks": locks
	}

## Play an animation respecting priority and locking rules
## Returns true if animation started playing, false if blocked
func play_animation(anim_name: String, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> bool:
	# Check if animation is configured
	if not _animations.has(anim_name):
		push_warning("AnimationHandler: Animation '%s' not configured" % anim_name)
		return false

	var animation_path := _resolve_animation_path(anim_name)
	if animation_path.is_empty():
		push_warning("AnimationHandler: Animation '%s' is configured but missing from the AnimationPlayer" % anim_name)
		return false
	
	# Don't restart if already playing the same animation
	if _current_animation == anim_name and is_playing():
		return true
	
	var anim_config: Dictionary = _animations[anim_name]
	var priority: int = anim_config["priority"]
	
	# Check if current animation is locked and has higher/equal priority
	if _locked and priority <= _current_priority:
		return false
	
	# Update state
	_current_animation = anim_name
	_current_priority = priority
	_locked = anim_config["locks"]
	
	if _locked:
		animation_locked.emit()
	
	# Defer actual play calls to avoid issues when called during physics callbacks
	var custom_blend_captured := custom_blend
	var custom_speed_captured := custom_speed
	var from_end_captured := from_end
	(func() -> void:
		if has_animation("RESET"):
			super.play("RESET")
			super.advance(0.0)
		super.play(animation_path, custom_blend_captured, custom_speed_captured, from_end_captured)
	).call_deferred()
	return true

func _resolve_animation_path(anim_name: String) -> StringName:
	if has_animation(anim_name):
		return StringName(anim_name)
	for library_name in get_animation_library_list():
		var library := get_animation_library(library_name)
		if library and library.has_animation(anim_name):
			return StringName("%s/%s" % [library_name, anim_name])
	return &""

func _on_animation_finished(_anim_name: StringName) -> void:
	if _locked:
		_locked = false
		animation_unlocked.emit()

## Query current state
func is_locked() -> bool:
	return _locked

func get_current_anim_name() -> String:
	return _current_animation

func get_current_priority() -> int:
	return _current_priority
