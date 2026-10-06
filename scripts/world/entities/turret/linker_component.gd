extends Node2D
class_name LinkerComponent

signal chain_started
signal chain_fired(target_count: int)

enum State {READY, CHARGING, COOLDOWN}

@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var laser_graphics: LaserGraphics = $LaserGraphics

## Color and opacity of the next-hop range circle around the chain's last target.
@export var hop_range_color := Color(0.25, 0.9, 1.0, 0.35)

var link_range := 90.0
var charge_duration := 1.0
var attack_cooldown := 3.0
var damage := 12
var knockback := 0.0
var targets_player := true

var _enabled := false
var _state := State.READY
var _charge_remaining := 0.0
var _cooldown_remaining := 0.0
var _has_fired := false
var _chain_targets: Array[Node2D] = []
var _chain_positions: Array[Vector2] = []
var _link_visuals: Array[LaserGraphics] = []
var _hop_range_indicator: RangeIndicator

func _ready() -> void:
	laser_graphics.hide()

func configure(p_link_range: float, p_charge_duration: float, p_attack_cooldown: float, p_damage: int, p_knockback: float) -> void:
	link_range = maxf(1.0, p_link_range)
	charge_duration = maxf(0.05, p_charge_duration)
	attack_cooldown = maxf(0.0, p_attack_cooldown)
	damage = maxi(0, p_damage)
	knockback = maxf(0.0, p_knockback)

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_reset()

func set_player_targeting_enabled(value: bool) -> void:
	targets_player = value

func get_cooldown_progress() -> float:
	if not _has_fired or attack_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _cooldown_remaining / attack_cooldown, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	_update_chain_visuals()
	if not _enabled:
		return
	match _state:
		State.READY:
			if _cooldown_remaining > 0.0:
				_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
				return
			var chain := _build_chain()
			if not chain.is_empty():
				_start_chain(chain)
		State.CHARGING:
			_extend_charging_chain()
			_charge_remaining -= delta
			if _charge_remaining <= 0.0:
				_fire_chain()
		State.COOLDOWN:
			_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
			if _cooldown_remaining <= 0.0:
				_state = State.READY

func _build_chain() -> Array[Node2D]:
	var chain: Array[Node2D] = []
	_extend_chain(chain)
	return chain

func _extend_chain(chain: Array[Node2D]) -> void:
	var candidates := _get_candidates()
	var visited: Dictionary[int, bool] = {}
	var previous_position := global_position
	for target: Node2D in chain:
		if is_instance_valid(target):
			visited[target.get_instance_id()] = true
	if not chain.is_empty():
		var last_target: Node2D = chain.back()
		if not is_instance_valid(last_target) or not _is_eligible_target(last_target):
			return
		previous_position = last_target.global_position
	while true:
		var next_target := _nearest_visible_candidate(previous_position, candidates, visited)
		if not next_target:
			break
		chain.append(next_target)
		visited[next_target.get_instance_id()] = true
		previous_position = next_target.global_position

func _extend_charging_chain() -> void:
	var previous_count := _chain_targets.size()
	_extend_chain(_chain_targets)
	if _chain_targets.size() == previous_count:
		return
	for index in range(previous_count, _chain_targets.size()):
		_chain_positions.append(_chain_targets[index].global_position)
	_build_link_visuals()
	_update_chain_visuals()

func _get_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var target := node as Node2D
		if _is_eligible_target(target):
			candidates.append(target)
	if targets_player:
		for node: Node in get_tree().get_nodes_in_group("player"):
			var target := node as Node2D
			if _is_eligible_target(target):
				candidates.append(target)
	return candidates

func _nearest_visible_candidate(from_position: Vector2, candidates: Array[Node2D], visited: Dictionary[int, bool]) -> Node2D:
	var nearest: Node2D
	var nearest_distance_sq := link_range * link_range
	for candidate: Node2D in candidates:
		if not is_instance_valid(candidate) or visited.has(candidate.get_instance_id()):
			continue
		var distance_sq := from_position.distance_squared_to(candidate.global_position)
		if distance_sq > nearest_distance_sq:
			continue
		if not line_of_sight.can_see(from_position, candidate.global_position):
			continue
		nearest = candidate
		nearest_distance_sq = distance_sq
	return nearest

func _is_eligible_target(target: Node2D) -> bool:
	return is_instance_valid(target) \
		and target.is_inside_tree() \
		and (not target.has_method("is_dead") or not target.is_dead()) \
		and (target.is_in_group("enemies") or (targets_player and target.is_in_group("player")))

func _start_chain(chain: Array[Node2D]) -> void:
	_clear_link_visuals()
	_chain_targets = chain
	_chain_positions.clear()
	_chain_positions.append(global_position)
	for target: Node2D in _chain_targets:
		_chain_positions.append(target.global_position)
	_state = State.CHARGING
	_charge_remaining = charge_duration
	_build_link_visuals()
	_hop_range_indicator = RangeIndicator.new()
	_hop_range_indicator.color = hop_range_color
	_hop_range_indicator.z_index = -1
	add_child(_hop_range_indicator)
	_hop_range_indicator.initialize(link_range)
	_hop_range_indicator.global_position = _chain_targets.back().global_position
	_hop_range_indicator.show_indicator()
	chain_started.emit()

func _fire_chain() -> void:
	_clear_hop_range_indicator()
	var damaged_count := 0
	for target: Node2D in _chain_targets:
		if not is_instance_valid(target) or not _is_eligible_target(target) or not target.has_method("was_hit"):
			continue
		var target_knockback := knockback if target.is_in_group("enemies") or target.is_in_group("player") else 0.0
		target.was_hit(damage, target_knockback, global_position)
		damaged_count += 1
	_state = State.COOLDOWN
	_cooldown_remaining = attack_cooldown
	_has_fired = true
	for visual: LaserGraphics in _link_visuals:
		if is_instance_valid(visual):
			visual.show_fire()
	chain_fired.emit(damaged_count)

func _build_link_visuals() -> void:
	for index in range(_link_visuals.size(), _chain_positions.size() - 1):
		var start_position := _chain_positions[index]
		var end_position := _chain_positions[index + 1]
		var segment := laser_graphics.create_instance()
		segment.name = "LinkSegment"
		add_child(segment)
		segment.fade_finished.connect(_on_segment_fade_finished.bind(segment))
		segment.set_beam_length(start_position.distance_to(end_position))
		segment.aim_from(start_position, start_position.direction_to(end_position))
		segment.show_telegraph()
		_link_visuals.append(segment)

func _update_chain_visuals() -> void:
	if _link_visuals.is_empty() or _chain_positions.size() != _chain_targets.size() + 1:
		return
	_chain_positions[0] = global_position
	for index in _chain_targets.size():
		var target := _chain_targets[index]
		if is_instance_valid(target):
			_chain_positions[index + 1] = target.global_position
	if is_instance_valid(_hop_range_indicator):
		var last_target: Node2D = _chain_targets.back()
		if is_instance_valid(last_target) and _is_eligible_target(last_target):
			_hop_range_indicator.global_position = last_target.global_position
			if not is_equal_approx(_hop_range_indicator.radius, link_range):
				_hop_range_indicator.initialize(link_range)
			_hop_range_indicator.show_indicator()
		else:
			_hop_range_indicator.hide_indicator()
	for index in _link_visuals.size():
		var start_position := _chain_positions[index]
		var end_position := _chain_positions[index + 1]
		var segment := _link_visuals[index]
		if not is_instance_valid(segment):
			continue
		segment.set_beam_length(start_position.distance_to(end_position))
		segment.aim_from(start_position, start_position.direction_to(end_position))

func _on_segment_fade_finished(target_alpha: float, segment: LaserGraphics) -> void:
	if not is_zero_approx(target_alpha):
		return
	_link_visuals.erase(segment)
	if is_instance_valid(segment):
		segment.queue_free()

func cancel_charge() -> void:
	if _state != State.CHARGING:
		return
	_state = State.READY
	_charge_remaining = 0.0
	_chain_targets.clear()
	_chain_positions.clear()
	_clear_link_visuals()

func _clear_link_visuals() -> void:
	_clear_hop_range_indicator()
	for visual: LaserGraphics in _link_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	_link_visuals.clear()

func _clear_hop_range_indicator() -> void:
	if is_instance_valid(_hop_range_indicator):
		_hop_range_indicator.queue_free()
	_hop_range_indicator = null

func _reset() -> void:
	_state = State.READY
	_cooldown_remaining = 0.0
	_charge_remaining = 0.0
	_has_fired = false
	_chain_targets.clear()
	_chain_positions.clear()
	_clear_link_visuals()

func _exit_tree() -> void:
	_clear_link_visuals()