extends Control

@onready var wave_manager: WaveManager = %WaveManager
@onready var resource_manager: ResourceManager = %ResourceManager
@onready var stress_level_manager: StressLevelManager = %StressLevelManager
@onready var score_manager: ScoreManager = %ScoreManager
@onready var player: Player = %Player

@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var scrap_label: Label = $ScrapContainer/ScrapLabel
@onready var wave_label: Label = $WaveContainer/WaveLabel
@onready var stress_label: Label = $StressContainer/StressLabel
@onready var build_phase_timer: Label = $BuildPhaseTimer
@onready var build_phase_texture: TextureRect = $WaveContainer/BuildPhaseTexture
@onready var combat_phase_texture: TextureRect = $WaveContainer/CombatPhaseTexture

func _ready() -> void:
	_initialize_values()
	_connect_signals()

func _initialize_values() -> void:
	set_health(int(stress_level_manager.current_stress))
	set_scrap(int(stress_level_manager.current_stress))
	set_wave(wave_manager.get_current_wave())
	set_stress(score_manager.calculate_score())
	build_phase_timer.visible = false
	build_phase_texture.visible = true
	combat_phase_texture.visible = false

func _connect_signals() -> void:
	player.damaged.connect(_on_player_damaged)
	stress_level_manager.stress_changed.connect(func(v): set_scrap(int(v)))
	stress_level_manager.stress_changed.connect(func(v): set_health(int(v)))
	score_manager.score_changed.connect(set_stress)
	wave_manager.combat_phase_started.connect(set_wave)
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	wave_manager.build_phase_tick.connect(_on_build_phase_tick)

func _on_player_damaged(current_health: int) -> void:
	set_health(current_health)

func set_health(amount: int) -> void:
	health_label.text = str(amount)

func set_scrap(amount: int) -> void:
	scrap_label.text = str(amount)

func set_wave(wave_index: int) -> void:
	wave_label.text = str(wave_index)

func set_stress(score_value: int) -> void:
	stress_label.text = str(score_value)

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
