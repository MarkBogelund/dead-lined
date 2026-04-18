extends Control

@onready var wave_manager: WaveManager = %WaveManager
@onready var capacity_manager: CapacityManager = %CapacityManager

@onready var wave_label: Label = $WaveContainer/WaveLabel
@onready var build_phase_timer: Label = $BuildPhaseTimer
@onready var build_phase_texture: TextureRect = $WaveContainer/BuildPhaseTexture
@onready var combat_phase_texture: TextureRect = $WaveContainer/CombatPhaseTexture

@onready var bar_track: ColorRect = $CapacityBar/BarTrack
@onready var indicator: ColorRect = $CapacityBar/Indicator
@onready var capacity_label: Label = $CapacityBar/CapacityLabel
@onready var crunch_time_threshold_line: ColorRect = $CapacityBar/CrunchTimeThreshold

const INDICATOR_DEFAULT_COLOR := Color.WHITE
const INDICATOR_CRUNCH_COLOR := Color.RED

func _ready() -> void:
	_initialize_values()
	_connect_signals()

func _initialize_values() -> void:
	set_wave(wave_manager.get_current_wave())
	call_deferred("_update_indicator", capacity_manager.current_capacity)
	call_deferred("_set_threshold_line_position", capacity_manager.crunch_time_threshold)
	build_phase_timer.visible = false
	build_phase_texture.visible = true
	combat_phase_texture.visible = false

func _connect_signals() -> void:
	capacity_manager.capacity_changed.connect(_update_indicator)
	capacity_manager.crunch_time_threshold_changed.connect(_tween_threshold_line)
	wave_manager.combat_phase_started.connect(set_wave)
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	wave_manager.build_phase_tick.connect(_on_build_phase_tick)

func _update_indicator(capacity: float) -> void:
	var bar_x := bar_track.position.x
	var bar_width := bar_track.size.x
	var center_x := bar_x + (capacity / 100.0) * bar_width
	indicator.position.x = center_x - indicator.size.x / 2.0
	capacity_label.text = "%d" % int(capacity)
	capacity_label.position.x = center_x - capacity_label.size.x / 2.0
	indicator.color = INDICATOR_CRUNCH_COLOR if capacity_manager.can_crunch_time() else INDICATOR_DEFAULT_COLOR

func _set_threshold_line_position(threshold: float) -> void:
	var bar_x := bar_track.position.x
	var bar_width := bar_track.size.x
	crunch_time_threshold_line.position.x = bar_x + (threshold / 100.0) * bar_width - crunch_time_threshold_line.size.x / 2.0

func _tween_threshold_line(threshold: float) -> void:
	var bar_x := bar_track.position.x
	var bar_width := bar_track.size.x
	var target_x := bar_x + (threshold / 100.0) * bar_width - crunch_time_threshold_line.size.x / 2.0
	var tween := create_tween()
	tween.tween_property(crunch_time_threshold_line, "position:x", target_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

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
