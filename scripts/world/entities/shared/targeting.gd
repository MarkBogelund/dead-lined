extends Node
class_name TargetingComponent

## Picks a target from a TargetingProfile's primary and secondary groups (rules in README "Targeting").

signal target_changed(new_target: Node2D, old_target: Node2D)

@export var profile: TargetingProfile
## Maximum distance to consider any target (-1 = unlimited). Per instance so range upgrades can change it.
@export var max_range: float = -1.0

const DEBUG_Z_INDEX := 1

var _current_target: Node2D
var _current_is_primary := false
var _disabled_groups: Dictionary[StringName, bool] = {}
var _debug: TargetingDebugDraw

func configure(p_profile: TargetingProfile) -> void:
	if not p_profile:
		push_error("%s: TargetingComponent requires a TargetingProfile" % get_parent().name)
		return
	profile = p_profile
	# Always created so debug flags can be toggled live; it only updates while one is on.
	if not _debug:
		_debug = TargetingDebugDraw.new()
		_debug.profile = profile
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
	var primary := _nearest(profile.primary_group, from_position, filter)
	var secondary := _nearest(profile.secondary_group, from_position, filter)
	if not is_instance_valid(_current_target) or not _is_candidate(_current_target, from_position, filter):
		_current_target = null

	var use_primary := _choose_primary(primary, secondary, from_position)
	var chosen: Node2D = primary if use_primary else secondary
	var retarget_radius := -1.0
	if chosen and _current_target and _current_is_primary == use_primary:
		retarget_radius = from_position.distance_to(_current_target.global_position) - profile.retarget_margin
		if from_position.distance_to(chosen.global_position) >= retarget_radius:
			chosen = _current_target

	_set_current(chosen, use_primary)
	if profile.is_debug_enabled():
		_update_debug(from_position, primary, secondary, retarget_radius)
	elif _debug.visible:
		_debug.hide()
	return _current_target

func _choose_primary(primary: Node2D, secondary: Node2D, from_position: Vector2) -> bool:
	if not secondary:
		return true
	if not primary:
		return false
	var primary_distance := from_position.distance_to(primary.global_position)
	if profile.primary_lock_radius >= 0.0 and primary_distance <= profile.primary_lock_radius:
		return true
	var on_secondary := _current_target != null and not _current_is_primary
	var margin: float = profile.return_to_primary_margin if on_secondary else profile.switch_to_secondary_margin
	return primary_distance < from_position.distance_to(secondary.global_position) + margin

func _set_current(target: Node2D, is_primary: bool) -> void:
	_current_is_primary = is_primary
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
	for group_name: StringName in [profile.primary_group, profile.secondary_group]:
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

func _update_debug(from_position: Vector2, primary: Node2D, secondary: Node2D, retarget_radius: float) -> void:
	_debug.show()
	_debug.global_position = from_position
	_debug.max_range = max_range
	_debug.lock_radius = profile.primary_lock_radius
	_debug.primary_distance = from_position.distance_to(primary.global_position) if primary else -1.0
	_debug.secondary_distance = from_position.distance_to(secondary.global_position) if secondary else -1.0
	# The lock radius overrides both margins, so neither ring is drawn smaller than it.
	_debug.switch_radius = maxf(_debug.secondary_distance + profile.switch_to_secondary_margin, profile.primary_lock_radius) if secondary else -1.0
	_debug.return_radius = maxf(_debug.secondary_distance + profile.return_to_primary_margin, profile.primary_lock_radius) if secondary else -1.0
	_debug.retarget_radius = retarget_radius
	_debug.target_offset = _current_target.global_position - from_position if _current_target else Vector2.ZERO
	_debug.target_is_primary = _current_is_primary
	_debug.queue_redraw()
