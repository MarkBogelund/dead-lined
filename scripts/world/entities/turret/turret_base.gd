extends StaticBody2D
class_name TurretBase

signal died

@onready var animation: AnimationHandler = $AnimationHandler
@onready var health: HealthComponent = $HealthComponent
@onready var interaction_range: InteractionZone = $InteractionZone
@onready var health_ui: HealthUIComponent = $HealthUIComponent
@onready var upgrader: TurretUpgradeComponent = $TurretUpgradeComponent
@onready var repair: RepairComponent = $RepairComponent
@onready var exclusion_zone: TurretExclusionZone = $TurretExclusionZone
@onready var hud: TurretHUD = $TurretHUD
@onready var range_indicator: RangeIndicator = $RangeIndicator
@onready var windup_particles: GPUParticles2D = get_node_or_null("WindupParticles") as GPUParticles2D
@onready var body_visual: CanvasItem = _get_body_visual()

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")
@onready var player: Player = get_tree().get_first_node_in_group("player")

var enabled := true
var _active := false
var _hit_flash_tween: Tween

@export_group("Presentation")
@export_range(0.01, 2.0, 0.01) var hit_flash_duration := 0.12
@export var hit_flash_shader: Shader

func _get_body_visual() -> CanvasItem:
	var sprite := get_node_or_null("Visuals/Sprite2D") as CanvasItem
	if sprite:
		return sprite
	return get_node_or_null("Visuals/AnimatedSprite2D") as CanvasItem

func _ready() -> void:
	add_to_group("turrets")
	_configure_hit_flash_materials()
	health_ui.setup(health)
	_configure_base_animations()
	if wave_manager:
		wave_manager.combat_phase_started.connect(_on_combat_phase_started)
		wave_manager.build_phase_started.connect(_on_build_phase_started)
	else:
		_active = true
		_on_combat_started()
	if game_over_manager:
		game_over_manager.game_over.connect(_on_game_over)
	interaction_range.player_entered.connect(_on_player_entered)
	interaction_range.player_exited.connect(_on_player_exited)
	repair.repaired.connect(health.heal)
	if player:
		repair.capacity_drained.connect(player.capacity.spend)
	repair.healing_started.connect(_on_healing_started)
	repair.healing_stopped.connect(_on_healing_stopped)
	if player and wave_manager:
		hud.setup(self, player, wave_manager)

func initialize_base(max_health: int, capacity_drain_rate: float, health_restore_rate: float, repair_amount_per_wrench_hit: int, exclusion_radius: float, display_range: float) -> void:
	health.initialize(max_health)
	repair.initialize(capacity_drain_rate, health_restore_rate, repair_amount_per_wrench_hit)
	exclusion_zone.initialize(exclusion_radius)
	range_indicator.initialize(display_range)

func _configure_base_animations() -> void:
	animation.configure_animation("repair", 3, true)
	animation.configure_animation("die", 4, true)

func _on_combat_phase_started(_wave: int) -> void:
	_active = true
	_on_combat_started()

func _on_build_phase_started() -> void:
	_active = false
	_on_combat_stopped()

func _on_game_over() -> void:
	_active = false
	enabled = false
	_on_combat_stopped()

func _on_player_entered() -> void:
	health_ui.set_player_in_range(true)
	range_indicator.show_indicator()

func _on_player_exited() -> void:
	health_ui.set_player_in_range(false)
	range_indicator.hide_indicator()

func _on_healing_started() -> void:
	if windup_particles:
		windup_particles.emitting = true

func _on_healing_stopped() -> void:
	if windup_particles:
		windup_particles.emitting = false

func _on_combat_started() -> void:
	pass

func _on_combat_stopped() -> void:
	pass

func is_turret_active() -> bool:
	return _active and enabled and not is_dead()

func receive_wrench_hit() -> bool:
	if health.is_full():
		return false
	repair.repair_once()
	animation.play_animation("repair")
	return true

func was_hit(amount: int, _knockback_force: float, _from_position: Vector2) -> void:
	if is_dead():
		return
	var was_fatal := health.take_damage(amount)
	if was_fatal:
		_handle_death()
	else:
		_play_hit_flash()

func _play_hit_flash() -> void:
	var flash_materials := _get_hit_flash_materials()
	if flash_materials.is_empty():
		return
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	for shader_material: ShaderMaterial in flash_materials:
		shader_material.set_shader_parameter("flash_amount", 1.0)
	_hit_flash_tween = create_tween()
	for shader_material: ShaderMaterial in flash_materials:
		_hit_flash_tween.parallel().tween_property(shader_material, "shader_parameter/flash_amount", 0.0, hit_flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _configure_hit_flash_materials() -> void:
	if not hit_flash_shader:
		push_error("TurretBase requires a hit_flash_shader to flash turret visuals when damaged")
		return
	_assign_hit_flash_material(body_visual)
	_assign_hit_flash_material(get_node_or_null("Visuals/Canon/Graphics") as CanvasItem)

func _assign_hit_flash_material(visual: CanvasItem) -> void:
	if not visual:
		return
	var material := visual.material as ShaderMaterial
	if not material:
		material = ShaderMaterial.new()
	visual.material = material
	material.shader = hit_flash_shader
	material.set_shader_parameter("flash_amount", 0.0)

func _get_hit_flash_materials() -> Array[ShaderMaterial]:
	var flash_materials: Array[ShaderMaterial] = []
	_add_hit_flash_material(body_visual, flash_materials)
	_add_hit_flash_material(get_node_or_null("Visuals/Canon/Graphics") as CanvasItem, flash_materials)
	return flash_materials

func _add_hit_flash_material(visual: CanvasItem, flash_materials: Array[ShaderMaterial]) -> void:
	var shader_material := visual.material as ShaderMaterial if visual else null
	if shader_material:
		flash_materials.append(shader_material)

func _before_death_animation() -> void:
	pass

func _handle_death() -> void:
	_before_death_animation()
	remove_from_group("turrets")
	enabled = false
	_active = false
	animation.play_animation("die")
	died.emit()

func get_damage_value() -> int:
	push_warning("TurretBase.get_damage_value() should be overridden")
	return 0

func apply_damage_upgrade(_amount: int) -> void:
	push_warning("TurretBase.apply_damage_upgrade() should be overridden")

func shake_screen(intensity: float, duration: float) -> void:
	camera_shake_manager.shake_screen(intensity, duration)

func is_dead() -> bool:
	return health.is_dead()