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
	
	# Don't restart if already playing the same animation
	if _current_animation == anim_name and is_playing():
		return true
	
	var anim_config = _animations[anim_name]
	var priority: int = anim_config["priority"]
	
	# Check if current animation is locked and has higher/equal priority
	if _locked and priority <= _current_priority:
		return false
	
	# Update state
	_current_animation = anim_name
	_current_priority = priority
	_locked = anim_config["locks"]
	
	if _locked:
		emit_signal("animation_locked")
	
	# Reset all animated properties to their RESET track values before playing
	if has_animation("RESET"):
		super.play("RESET")
		super.advance(0.0)
	
	# Call parent play method
	super.play(anim_name, custom_blend, custom_speed, from_end)
	return true

func _on_animation_finished(_anim_name: StringName) -> void:
	if _locked:
		_locked = false
		emit_signal("animation_unlocked")

## Query current state
func is_locked() -> bool:
	return _locked

func get_current_anim_name() -> String:
	return _current_animation

func get_current_priority() -> int:
	return _current_priority
