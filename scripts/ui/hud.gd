extends Control

@export var crunch_time_effects: CrunchTimeEffects = preload("res://resources/crunch_time_effects.tres")

@onready var wave_manager: WaveManager = %WaveManager
@onready var player: Player = %Player
@onready var score_manager: ScoreManager = %ScoreManager

@onready var wave_label: Label = %WaveLabel
@onready var build_phase_timer: Label = %BuildPhaseTimer
@onready var build_phase_texture: TextureRect = %BuildPhaseTexture
@onready var combat_phase_texture: TextureRect = %CombatPhaseTexture

@onready var capacity_bar: NinePatchRect = $CapacityBar
@onready var capacity_fill_clip: Control = $CapacityBar/CapacityFillClip
@onready var capacity_fill: NinePatchRect = $CapacityBar/CapacityFillClip/CapacityFill
@onready var capacity_label: Label = $CapacityBar/CapacityLabel
@onready var crunch_time_threshold_line: ColorRect = $CapacityBar/CrunchTimeThreshold
@onready var crunch_time_label: Label = %CrunchTimeReadyLabel
@onready var score_label: Label = %ScoreLabel
@onready var floating_score_text: FloatingScoreText = $FloatingScoreText

@onready var animation_handler: AnimationHandler = $AnimationHandler
@onready var _capacity_overlay: CapacityOverlay = %CapacityOverlay

var _last_capacity: float = 0.0
var _capacity_fill_layout_initialized := false
var _capacity_fill_clip_left_inset := 0.0
var _capacity_fill_clip_right_inset := 0.0
var _capacity_fill_left_overhang := 0.0
var _capacity_fill_right_overhang := 0.0

func _ready() -> void:
	_initialize_values()
	_connect_signals()
	animation_handler.configure_animation("score_update", 0, false)
	animation_handler.configure_animation("capacity_ready", 0, false)
	animation_handler.configure_animation("capacity_active", 0, false)
	animation_handler.configure_animation("capacity_change", 1, false)
	animation_handler.animation_finished.connect(_on_animation_finished)
	_play_capacity_state_animation()

func _initialize_values() -> void:
	_last_capacity = player.capacity.current_capacity
	set_wave(wave_manager.get_current_wave())
	call_deferred("_initialize_capacity_fill_layout")
	build_phase_timer.visible = false
	build_phase_texture.visible = true
	combat_phase_texture.visible = false
	crunch_time_label.visible = false
	capacity_bar.pivot_offset = capacity_bar.size / 2.0
	_update_crunch_time_ready_state()

func _connect_signals() -> void:
	player.capacity.capacity_changed.connect(_on_capacity_changed)
	player.capacity.crunch_time_threshold_changed.connect(_tween_threshold_line)
	player.capacity.crunch_time_unlocked.connect(_on_crunch_time_unlocked)
	player.crunch_time.crunch_time_started.connect(_on_crunch_time_started)
	player.crunch_time.crunch_time_ended.connect(_on_crunch_time_ended)
	wave_manager.combat_phase_started.connect(set_wave)
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	wave_manager.build_phase_tick.connect(_on_build_phase_tick)
	score_manager.score_earned.connect(_on_score_earned)
	floating_score_text.arrived.connect(_on_floating_text_arrived)
	capacity_fill.resized.connect(_update_capacity_fill_shader_width)
	capacity_bar.resized.connect(_on_capacity_bar_resized)

func _initialize_capacity_fill_layout() -> void:
	_capacity_fill_clip_left_inset = capacity_fill_clip.position.x
	_capacity_fill_clip_right_inset = capacity_bar.size.x - capacity_fill_clip.position.x - capacity_fill_clip.size.x
	_capacity_fill_left_overhang = - capacity_fill.position.x
	_capacity_fill_right_overhang = capacity_fill.position.x + capacity_fill.size.x - capacity_fill_clip.size.x
	_capacity_fill_layout_initialized = true
	_update_capacity_fill(player.capacity.current_capacity)
	_set_threshold_line_position(player.capacity.crunch_time_threshold)
	_update_capacity_fill_shader_width()

func _on_capacity_bar_resized() -> void:
	if not _capacity_fill_layout_initialized:
		return
	_update_capacity_fill(player.capacity.current_capacity)
	_set_threshold_line_position(player.capacity.crunch_time_threshold)

func _update_capacity_fill_shader_width() -> void:
	var shader_material := capacity_fill.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("control_width", capacity_fill.size.x)

func _on_capacity_changed(capacity: float) -> void:
	var delta := capacity - _last_capacity
	_last_capacity = capacity
	_update_capacity_fill(capacity)
	_update_crunch_time_ready_state()
	if delta > 0.0:
		_play_capacity_change_animation()
	elif delta < 0.0:
		_play_capacity_change_animation()

func _on_crunch_time_unlocked() -> void:
	_update_crunch_time_ready_state()
	_play_capacity_state_animation()

func _on_crunch_time_started(_buffs: Dictionary) -> void:
	_update_crunch_time_ready_state()
	_capacity_overlay.set_crunch_time_active(true)
	_play_capacity_state_animation()

func _on_crunch_time_ended(_buffs: Dictionary, _duration: float) -> void:
	_update_crunch_time_ready_state()
	_capacity_overlay.set_crunch_time_active(false)
	_play_capacity_state_animation()

func _update_capacity_fill(capacity: float) -> void:
	if not _capacity_fill_layout_initialized:
		return
	var maximum := player.capacity.get_max()
	var capacity_fraction := clampf(capacity / maximum if maximum > 0.0 else 0.0, 0.0, 1.0)
	var full_width := capacity_bar.size.x - _capacity_fill_clip_left_inset - _capacity_fill_clip_right_inset
	var target_width := full_width * capacity_fraction
	var minimum_width := float(capacity_fill.patch_margin_left + capacity_fill.patch_margin_right)
	var rendered_width := maxf(target_width + _capacity_fill_left_overhang + _capacity_fill_right_overhang, minimum_width)
	var fill_right := target_width + _capacity_fill_right_overhang
	capacity_fill_clip.anchor_left = 0.0
	capacity_fill_clip.anchor_right = 0.0
	capacity_fill_clip.offset_left = _capacity_fill_clip_left_inset
	capacity_fill_clip.offset_right = _capacity_fill_clip_left_inset + target_width
	capacity_fill_clip.visible = capacity_fraction > 0.0
	capacity_fill.anchor_left = 0.0
	capacity_fill.anchor_right = 0.0
	capacity_fill.offset_left = fill_right - rendered_width
	capacity_fill.offset_right = fill_right
	capacity_label.text = "%d" % int(capacity)
	_capacity_overlay.update_capacity(capacity, maximum)

func _update_crunch_time_ready_state() -> void:
	var is_ready := player.capacity.can_crunch_time() and not player.crunch_time.is_crunch_time_active()
	crunch_time_label.visible = is_ready
	if not is_ready:
		crunch_time_label.scale = Vector2.ONE

func _set_threshold_line_position(threshold: float) -> void:
	if not _capacity_fill_layout_initialized:
		return
	var maximum := player.capacity.get_max()
	var fraction := threshold / maximum if maximum > 0.0 else 0.0
	var full_width := capacity_bar.size.x - _capacity_fill_clip_left_inset - _capacity_fill_clip_right_inset
	crunch_time_threshold_line.position.x = _capacity_fill_clip_left_inset + fraction * full_width - crunch_time_threshold_line.size.x / 2.0

func _tween_threshold_line(threshold: float) -> void:
	if not _capacity_fill_layout_initialized:
		return
	var maximum := player.capacity.get_max()
	var fraction := threshold / maximum if maximum > 0.0 else 0.0
	var full_width := capacity_bar.size.x - _capacity_fill_clip_left_inset - _capacity_fill_clip_right_inset
	var target_x := _capacity_fill_clip_left_inset + fraction * full_width - crunch_time_threshold_line.size.x / 2.0
	var tween := create_tween()
	tween.tween_property(crunch_time_threshold_line, "position:x", target_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _play_capacity_state_animation() -> void:
	if player.crunch_time.is_crunch_time_active():
		animation_handler.play_animation("capacity_active")
	elif player.capacity.can_crunch_time():
		animation_handler.play_animation("capacity_ready")
	else:
		animation_handler.stop()
		capacity_bar.position.y = 11.0
		capacity_bar.scale = Vector2.ONE

func _play_capacity_change_animation() -> void:
	if player.crunch_time.is_crunch_time_active():
		return
	animation_handler.play_animation("capacity_change")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"capacity_change" or animation_name == &"score_update":
		_play_capacity_state_animation()

func set_wave(wave_index: int) -> void:
	wave_label.text = str(wave_index)

func _on_build_phase_started() -> void:
	build_phase_timer.visible = true
	build_phase_texture.visible = true
	combat_phase_texture.visible = false

func _on_combat_phase_started(_wave_index: int) -> void:
	build_phase_timer.visible = false
	build_phase_texture.visible = false
	combat_phase_texture.visible = true

func _on_build_phase_tick(time_left: float) -> void:
	build_phase_timer.text = str(ceili(time_left))

func _on_score_earned(points: int, world_position: Vector2, color: Color) -> void:
	floating_score_text.spawn("+%d" % points, color, world_position)

func _on_floating_text_arrived() -> void:
	score_label.text = "$%d" % score_manager.calculate_score()
	animation_handler.play_animation("score_update")
