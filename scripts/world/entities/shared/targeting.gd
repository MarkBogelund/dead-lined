extends Node
class_name TargetingComponent

## Picks a target from a TargetingProfile's high/low priority groups.
## Rules (in order): drop an invalid current target; a high-priority target inside lock_radius wins;
## otherwise the low-priority target wins only when dist(high) > dist(low) + cross_priority_margin
## (and keeps winning until dist(high) < dist(low) + cross_priority_return_margin);
## within the chosen tier the current target is kept unless a challenger is closer by same_priority_margin.

signal target_changed(new_target: Node2D, old_target: Node2D)

@export var profile: TargetingProfile
## Maximum distance to consider any target (-1 = unlimited). Per instance so range upgrades can change it.
@export var max_range: float = -1.0

const DEBUG_Z_INDEX := 1

var _current_target: Node2D
var _current_is_high := false
var _disabled_groups: Dictionary[StringName, bool] = {}
var _debug: TargetingDebugDraw

func configure(p_profile: TargetingProfile) -> void:
	if not p_profile:
		push_error("%s: TargetingComponent requires a TargetingProfile" % get_parent().name)
		return
	profile = p_profile
	if profile.debug_draw and not _debug:
		_debug = TargetingDebugDraw.new()
		_debug.z_index = DEBUG_Z_INDEX
		add_child(_debug)

func initialize(s_max_range: float) -> void:
	max_range = s_max_range

func set_group_enabled(group_name: StringName, is_enabled: bool) -> void:
	if is_enabled:
		_disabled_groups.erase(group_name)
	else:
		_disabled_groups[group_name] = true

## filter: optional callable(Node2D) -> bool; return false to exclude a candidate (e.g. line of sight).
func get_best_target(from_position: Vector2, filter: Callable = Callable()) -> Node2D:
	if not profile:
		return null
	var high := _nearest(profile.high_priority_group, from_position, filter)
	var low := _nearest(profile.low_priority_group, from_position, filter)
	if not is_instance_valid(_current_target) or not _is_candidate(_current_target, from_position, filter):
		_current_target = null

	var use_high := _choose_high_tier(high, low, from_position)
	var chosen: Node2D = high if use_high else low
	var takeover_radius := -1.0
	if chosen and _current_target and _current_is_high == use_high:
		var current_distance := from_position.distance_to(_current_target.global_position)
		takeover_radius = current_distance - profile.same_priority_margin
		if from_position.distance_to(chosen.global_position) >= takeover_radius:
			chosen = _current_target

	_set_current(chosen, use_high)
	if _debug:
		_update_debug(from_position, high, low, takeover_radius)
	return _current_target

func _choose_high_tier(high: Node2D, low: Node2D, from_position: Vector2) -> bool:
	if not low:
		return true
	if not high:
		return false
	var high_distance := from_position.distance_to(high.global_position)
	if profile.lock_radius >= 0.0 and high_distance <= profile.lock_radius:
		return true
	return high_distance < from_position.distance_to(low.global_position) + _active_cross_margin()

## Hysteresis: once on the low tier, the high tier must come closer (return margin) to win it back.
func _active_cross_margin() -> float:
	var on_low := _current_target != null and not _current_is_high
	return profile.cross_priority_return_margin if on_low else profile.cross_priority_margin

func _set_current(target: Node2D, is_high: bool) -> void:
	_current_is_high = is_high
	if target == _current_target:
		return
	var old := _current_target
	_current_target = target
	target_changed.emit(target, old)

func _nearest(group_name: StringName, from_position: Vector2, filter: Callable) -> Node2D:
	if group_name.is_empty() or _disabled_groups.has(group_name):
		return null
	var best: Node2D = null
	var best_distance_sq := INF
	for node: Node in get_tree().get_nodes_in_group(group_name):
		var candidate := node as Node2D
		if not _passes_basic_checks(candidate, from_position, filter):
			continue
		var distance_sq := from_position.distance_squared_to(candidate.global_position)
		if distance_sq < best_distance_sq:
			best = candidate
			best_distance_sq = distance_sq
	return best

func _is_candidate(target: Node2D, from_position: Vector2, filter: Callable) -> bool:
	var in_enabled_group := false
	for group_name: StringName in [profile.high_priority_group, profile.low_priority_group]:
		if not group_name.is_empty() and not _disabled_groups.has(group_name) and target.is_in_group(group_name):
			in_enabled_group = true
	return in_enabled_group and _passes_basic_checks(target, from_position, filter)

func _passes_basic_checks(target: Node2D, from_position: Vector2, filter: Callable) -> bool:
	if not target or not target.is_inside_tree():
		return false
	if target.has_method("is_dead") and target.is_dead():
		return false
	if max_range >= 0.0 and from_position.distance_squared_to(target.global_position) > max_range * max_range:
		return false
	return not filter.is_valid() or filter.call(target)

func _update_debug(from_position: Vector2, high: Node2D, low: Node2D, takeover_radius: float) -> void:
	_debug.global_position = from_position
	_debug.lock_radius = profile.lock_radius
	_debug.max_range = max_range
	_debug.high_distance = from_position.distance_to(high.global_position) if high else -1.0
	_debug.low_distance = from_position.distance_to(low.global_position) if low else -1.0
	_debug.switch_radius = _debug.low_distance + _active_cross_margin() if low else -1.0
	_debug.takeover_radius = takeover_radius
	_debug.target_offset = _current_target.global_position - from_position if _current_target else Vector2.ZERO
	_debug.target_is_high = _current_is_high
	_debug.queue_redraw()
