extends StaticBody2D
class_name TurretBase

signal died
signal upgrade_purchased(cost: float)
signal sold(refund: float)
signal attack_cooldown_progress_changed(progress: float)

@onready var animation: AnimationHandler = $AnimationHandler
@onready var health: HealthComponent = $HealthComponent
@onready var interaction_range: InteractionZone = $InteractionZone
@onready var health_ui: HealthUIComponent = $HealthUIComponent
@onready var upgrader: TurretUpgradeComponent = $TurretUpgradeComponent
@onready var repair: RepairComponent = $RepairComponent
@onready var exclusion_zone: TurretExclusionZone = $TurretExclusionZone
@onready var hud: TurretHUD = $TurretHUD
@onready var range_indicator: RangeIndicator = $RangeIndicator
@onready var visuals: Node2D = $Visuals
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var repair_animation: AnimationPlayer = $RepairAnimationPlayer

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")
@onready var player: Player = get_tree().get_first_node_in_group("player")

var enabled := true
## Floor for attack cooldowns; upgrades below it are clamped with a warning.
const MIN_ATTACK_COOLDOWN := 0.5
var total_invested := 0.0
var _base_stats: TurretStats
var _stat_values: TurretStatValues
var _active := false
var _repairing := false
var _selling := false
var _sell_refund_ratio := 0.0
var _stops_targeting_player_when_maxed := false
var _hit_flash_tween: Tween
var _is_critical := false
var _death_burnout_active := false
var _last_cooldown_progress := -1.0

@export_group("Presentation")
@export_range(0.01, 2.0, 0.01) var hit_flash_duration := 0.12
## Health fraction at or below which the turret looks broken and gets an off-screen indicator.
@export_range(0.0, 1.0, 0.05) var critical_health_ratio := 0.25
## Keyed by the die animation; maps critical damage 1->0 and white flash 0->1.
@export_range(0.0, 1.0, 0.01) var death_burnout_progress := 0.0:
	set = _set_death_burnout_progress
## turret_surface.gdshader: combines the hit flash and gold shine effects (see shaders/include/).
@export var surface_shader: Shader
@export_range(0.05, 2.0, 0.05) var sell_fade_duration := 0.25

func _ready() -> void:
	add_to_group("turrets")
	_configure_surface_materials()
	health_ui.setup(health)
	attack_cooldown_progress_changed.connect(health_ui.set_secondary_progress)
	_configure_base_animations()
	if wave_manager:
		wave_manager.combat_phase_started.connect(_on_combat_phase_started)
		wave_manager.build_phase_started.connect(_on_build_phase_started)
	else:
		_active = true
		_on_combat_started()
	if game_over_manager:
		game_over_manager.game_over.connect(_on_game_over)
	health.health_changed.connect(_on_health_changed)
	repair.repaired.connect(health.heal)
	if player:
		repair.capacity_drained.connect(player.capacity.spend)
	upgrader.upgraded.connect(_on_upgraded)
	health_ui.set_level(upgrader.level)
	if upgrader.is_max_level():
		_on_maxed()
	hud.opened.connect(range_indicator.show_indicator)
	hud.closed.connect(range_indicator.hide_indicator)
	hud.setup(self)

func initialize_base(stats: TurretStats) -> void:
	_base_stats = stats
	_stat_values = TurretStatValues.from_stats(stats)
	health.initialize(stats.max_health)
	repair.initialize(stats.repair_cost_per_second, stats.repair_health_per_second)
	range_indicator.initialize(stats.attack_range)
	upgrader.initialize(stats.upgrades)
	_sell_refund_ratio = stats.sell_refund_ratio
	_stops_targeting_player_when_maxed = stats.stops_targeting_player_when_maxed

## Called by ShopManager on placement so the sell refund includes the purchase price.
func set_purchase_price(price: float) -> void:
	total_invested = price

## Called by ShopManager on placement; the radius belongs to the shop entry.
func set_exclusion_radius(radius: float) -> void:
	exclusion_zone.initialize(radius)

## Called by ShopManager on placement; the upgrade panel outline uses the shop entry's colors.
func set_panel_colors(start_color: Color, end_color: Color) -> void:
	hud.set_outline_colors(start_color, end_color)

func get_level() -> int:
	return upgrader.level

func get_stat_values() -> TurretStatValues:
	return _stat_values

## The stats the next upgrade would give, or null when maxed.
func get_next_level_stats() -> TurretStatValues:
	var upgrade := upgrader.next_upgrade()
	return _stats_after(upgrade) if upgrade else null

func is_critical() -> bool:
	return _is_critical and not is_dead()

func _on_health_changed(current: int, maximum: int) -> void:
	# The death burnout owns the damage uniforms from here on.
	if is_dead():
		return
	_set_critical(maximum > 0 and float(current) / maximum <= critical_health_ratio)

## Damage effect: owns only the damage_* / crack_* uniforms.
func _set_critical(value: bool) -> void:
	if value == _is_critical:
		return
	_is_critical = value
	for shader_material: ShaderMaterial in _get_surface_materials():
		shader_material.set_shader_parameter("damage_amount", 1.0 if value else 0.0)

func is_max_level() -> bool:
	return upgrader.is_max_level()

func get_upgrade_cost() -> float:
	var upgrade := upgrader.next_upgrade()
	return upgrade.cost if upgrade else 0.0

func can_upgrade() -> bool:
	var upgrade := upgrader.next_upgrade()
	return upgrade != null and _can_manage() and player != null and player.capacity.can_afford(upgrade.cost)

func try_upgrade() -> void:
	if not can_upgrade():
		return
	var cost := get_upgrade_cost()
	total_invested += cost
	upgrader.apply_next()
	upgrade_purchased.emit(cost)

## upgrade_charge is scaled so it finishes exactly when the upgrade hold completes.
func start_upgrade_charge(hold_duration: float) -> void:
	# A new hold cuts the previous burst short; its particles keep playing out.
	animation.stop_animation("upgrade")
	var length := animation.get_animation("upgrade_charge").length
	animation.play_animation("upgrade_charge", -1, length / hold_duration)

func stop_upgrade_charge() -> void:
	animation.stop_animation("upgrade_charge")

func _set_death_burnout_progress(value: float) -> void:
	death_burnout_progress = value
	if not _death_burnout_active:
		return
	for shader_material: ShaderMaterial in _get_surface_materials():
		shader_material.set_shader_parameter("damage_amount", 1.0 - value)
		shader_material.set_shader_parameter("flash_amount", value)

func get_sell_value() -> float:
	var refund := total_invested * _sell_refund_ratio
	return minf(refund, player.capacity.get_max()) if player else refund

func can_sell() -> bool:
	return _can_manage()

func sell() -> void:
	if not can_sell():
		return
	_selling = true
	enabled = false
	_active = false
	_set_critical(false)
	if _repairing:
		_stop_repairing()
	_on_combat_stopped()
	remove_from_group("turrets")
	body_collision.set_deferred("disabled", true)
	health_ui.hide()
	range_indicator.hide_indicator()
	sold.emit(get_sell_value())
	var tween := create_tween().set_parallel()
	tween.tween_property(visuals, "modulate:a", 0.0, sell_fade_duration)
	tween.tween_property(visuals, "scale", Vector2.ZERO, sell_fade_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

## Upgrading and selling are build-phase actions; standalone scenes without a WaveManager allow them.
func _can_manage() -> bool:
	return not _selling and not is_dead() and (wave_manager == null or wave_manager.is_build_phase())

## Upgrade values multiply the base stats (not the previous level); -1 keeps the previous level's value.
func _stats_after(upgrade: TurretUpgrade) -> TurretStatValues:
	var next := TurretStatValues.new()
	next.max_health = roundi(_base_stats.max_health * upgrade.max_health) if upgrade.max_health >= 0.0 else _stat_values.max_health
	next.damage = roundi(_base_stats.damage * upgrade.damage) if upgrade.damage >= 0.0 else _stat_values.damage
	next.attack_range = _base_stats.attack_range * upgrade.attack_range if upgrade.attack_range >= 0.0 else _stat_values.attack_range
	next.attack_cooldown = maxf(MIN_ATTACK_COOLDOWN, _base_stats.attack_cooldown * upgrade.attack_cooldown) if upgrade.attack_cooldown >= 0.0 else _stat_values.attack_cooldown
	return next

func _on_upgraded(upgrade: TurretUpgrade) -> void:
	var next := _stats_after(upgrade)
	if upgrade.max_health >= 0.0:
		health.set_max_health(next.max_health)
	if upgrade.damage >= 0.0:
		set_damage(next.damage)
	if upgrade.attack_range >= 0.0:
		set_attack_range(next.attack_range)
	if upgrade.attack_cooldown >= 0.0:
		var cooldown := _base_stats.attack_cooldown * upgrade.attack_cooldown
		if cooldown < MIN_ATTACK_COOLDOWN:
			push_warning("%s level %d attack_cooldown %.2f is below MIN_ATTACK_COOLDOWN %.2f; clamping" % [name, upgrader.level, cooldown, MIN_ATTACK_COOLDOWN])
		set_attack_cooldown(next.attack_cooldown)
	_stat_values = next
	health_ui.set_level(upgrader.level)
	animation.play_animation("upgrade")
	if upgrader.is_max_level():
		_on_maxed()

func _on_maxed() -> void:
	_set_gold_shine(true)
	if _stops_targeting_player_when_maxed:
		_stop_targeting_player()

## Override: stop selecting the player as a target. Attacks may still hit the player.
func _stop_targeting_player() -> void:
	pass

func _configure_base_animations() -> void:
	animation.configure_animation("upgrade_charge", 2, true)
	animation.configure_animation("upgrade", 3, true)
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

## Subclasses overriding _physics_process must call super._physics_process(delta).
func _physics_process(delta: float) -> void:
	_update_repair(delta)
	var cooldown_progress := get_attack_cooldown_progress() if is_turret_active() else 1.0
	if not is_equal_approx(cooldown_progress, _last_cooldown_progress):
		_last_cooldown_progress = cooldown_progress
		attack_cooldown_progress_changed.emit(cooldown_progress)

func _update_repair(delta: float) -> void:
	if _can_hold_repair(delta):
		if not _repairing:
			_repairing = true
			repair_animation.play("repair")
		repair.try_repair(delta, player.capacity.get_current())
	elif _repairing:
		_stop_repairing()

func _can_hold_repair(delta: float) -> bool:
	return player != null \
		and enabled \
		and not is_dead() \
		and not health.is_full() \
		and interaction_range.is_player_in_range() \
		and Input.is_action_pressed("repair") \
		and player.capacity.can_afford(repair.get_capacity_cost(delta))

func _stop_repairing() -> void:
	_repairing = false
	repair.reset()
	repair_animation.play("RESET")

func _on_combat_started() -> void:
	pass

func _on_combat_stopped() -> void:
	pass

func is_turret_active() -> bool:
	return _active and enabled and not is_dead()

func get_attack_cooldown_progress() -> float:
	return 1.0

func was_hit(amount: int, _knockback_force: float, _from_position: Vector2) -> void:
	if is_dead() or _selling:
		return
	var was_fatal := health.take_damage(amount)
	if was_fatal:
		_handle_death()
	else:
		_play_hit_flash()

## Hit flash effect: owns only the flash_* uniforms.
func _play_hit_flash() -> void:
	var surface_materials := _get_surface_materials()
	if surface_materials.is_empty():
		return
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	for shader_material: ShaderMaterial in surface_materials:
		shader_material.set_shader_parameter("flash_amount", 1.0)
	_hit_flash_tween = create_tween()
	for shader_material: ShaderMaterial in surface_materials:
		_hit_flash_tween.parallel().tween_property(shader_material, "shader_parameter/flash_amount", 0.0, hit_flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Gold shine effect: owns only the gold_* / shine_* / sparkle_* uniforms.
func _set_gold_shine(enabled_shine: bool) -> void:
	for shader_material: ShaderMaterial in _get_surface_materials():
		shader_material.set_shader_parameter("gold_amount", 1.0 if enabled_shine else 0.0)

func _configure_surface_materials() -> void:
	if not surface_shader:
		push_error("TurretBase requires a surface_shader for hit flash and gold shine")
		return
	var shader_material := visuals.material as ShaderMaterial
	if not shader_material:
		push_error("TurretBase Visuals requires a local turret surface ShaderMaterial")
		return
	shader_material.shader = surface_shader

func _get_surface_materials() -> Array[ShaderMaterial]:
	var surface_materials: Array[ShaderMaterial] = []
	var shader_material := visuals.material as ShaderMaterial
	if shader_material:
		surface_materials.append(shader_material)
	return surface_materials

func _before_death_animation() -> void:
	pass

## Runs alongside the die animation: the critical red fades out as the sprite flashes white.
func _play_death_burnout() -> void:
	_death_burnout_active = _is_critical
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	_set_death_burnout_progress(0.0)

func _handle_death() -> void:
	if _repairing:
		_stop_repairing()
	_before_death_animation()
	remove_from_group("turrets")
	_play_death_burnout()
	enabled = false
	_active = false
	animation.play_animation("die")
	died.emit()

func get_damage_value() -> int:
	push_warning("TurretBase.get_damage_value() should be overridden")
	return 0

func set_damage(_value: int) -> void:
	push_warning("TurretBase.set_damage() should be overridden")

func set_attack_range(_value: float) -> void:
	push_warning("TurretBase.set_attack_range() should be overridden")

func set_attack_cooldown(_value: float) -> void:
	push_warning("TurretBase.set_attack_cooldown() should be overridden")

func shake_screen(intensity: float, duration: float) -> void:
	camera_shake_manager.shake_screen(intensity, duration)

func is_dead() -> bool:
	return health.is_dead()