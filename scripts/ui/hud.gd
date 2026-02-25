extends Control

@onready var wave_manager: WaveManager = %WaveManager
@onready var resource_manager: ResourceManager = %ResourceManager
@onready var player: Player = %Player

@onready var health_label: Label = $HealthTexture/HealthLabel
@onready var scrap_label: Label = $ScrapTexture/ScrapLabel
@onready var wave_label: Label = $WaveTexture/WaveLabel

func _ready() -> void:
	_initialize_values()
	_connect_signals()

func _initialize_values() -> void:
	set_health(player.get_health())
	set_scrap(resource_manager.scrap_amount)
	set_wave(wave_manager.get_current_wave())

func _connect_signals() -> void:
	player.damaged.connect(_on_player_damaged)
	resource_manager.scrap_amount_changed.connect(set_scrap)
	wave_manager.combat_phase_started.connect(set_wave)

func _on_player_damaged(current_health: int) -> void:
	set_health(current_health)

func set_health(amount: int) -> void:
	health_label.text = str(amount)

func set_scrap(amount: int) -> void:
	scrap_label.text = str(amount)

func set_wave(wave_index: int) -> void:
	wave_label.text = str(wave_index)
