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
		apply_resets()
		super.play(animation_path, custom_blend_captured, custom_speed_captured, from_end_captured)
	).call_deferred()
	return true

## Stops a (typically looping) animation if it is the current one and restores RESET values.
## Deferred like play_animation(): RESETs toggle collision state, which physics callbacks forbid.
func stop_animation(anim_name: String) -> void:
	if _current_animation != anim_name:
		return
	_release_current()
	(func() -> void:
		super.stop()
		if apply_resets():
			super.stop(true)
	).call_deferred()

## Plays the animation from the start even if it is already current (e.g. repeated hits).
## Safe inside physics callbacks: the RESET and replay are deferred by play_animation().
func restart_animation(anim_name: String) -> bool:
	if _current_animation == anim_name:
		_release_current()
	return play_animation(anim_name)

func _release_current() -> void:
	_current_animation = ""
	_current_priority = 0
	if _locked:
		_locked = false
		animation_unlocked.emit()

## Applies the RESET of every library, so inherited scenes can reset their own tracks in an extra library.
func apply_resets() -> bool:
	var applied := false
	for library_name: StringName in get_animation_library_list():
		if not get_animation_library(library_name).has_animation(&"RESET"):
			continue
		super.play(&"RESET" if library_name.is_empty() else StringName("%s/RESET" % library_name))
		super.advance(0.0)
		applied = true
	return applied

## True when the animation exists in any of this player's libraries.
func has_configured_animation(anim_name: String) -> bool:
	return not _resolve_animation_path(anim_name).is_empty()

func get_animation_length(anim_name: String) -> float:
	return get_animation(_resolve_animation_path(anim_name)).length

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
