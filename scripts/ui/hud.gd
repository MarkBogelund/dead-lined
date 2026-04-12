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

func _ready() -> void:
	_initialize_values()
	_connect_signals()

func _initialize_values() -> void:
	set_wave(wave_manager.get_current_wave())
	call_deferred("_update_indicator", capacity_manager.current_capacity)
	build_phase_timer.visible = false
	build_phase_texture.visible = true
	combat_phase_texture.visible = false

func _connect_signals() -> void:
	capacity_manager.capacity_changed.connect(_update_indicator)
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
