extends StaticBody2D
class_name TurretBase

signal died
signal upgrade_purchased(cost: float)
signal sold(refund: float)

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
@onready var body_visual: CanvasItem = _get_body_visual()

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")
@onready var player: Player = get_tree().get_first_node_in_group("player")

var enabled := true
var total_invested := 0.0
var _active := false
var _repairing := false
var _selling := false
var _sell_refund_ratio := 0.0
var _stops_targeting_player_when_maxed := false
var _hit_flash_tween: Tween

@export_group("Presentation")
@export_range(0.01, 2.0, 0.01) var hit_flash_duration := 0.12
@export var hit_flash_shader: Shader
@export_range(0.05, 2.0, 0.05) var sell_fade_duration := 0.25

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
	upgrader.upgraded.connect(_on_upgraded)
	health_ui.set_level(upgrader.level)
	if upgrader.is_max_level():
		_on_maxed()
	if wave_manager:
		hud.setup(self, wave_manager)

func initialize_base(stats: TurretStats, display_range: float) -> void:
	health.initialize(stats.max_health)
	repair.initialize(stats.capacity_drain_rate, stats.health_restore_rate)
	exclusion_zone.initialize(stats.exclusion_radius)
	range_indicator.initialize(display_range)
	upgrader.initialize(stats.upgrades)
	_sell_refund_ratio = stats.sell_refund_ratio
	_stops_targeting_player_when_maxed = stats.stops_targeting_player_when_maxed

## Called by ShopManager on placement so the sell refund includes the purchase price.
func set_purchase_price(price: float) -> void:
	total_invested = price

func get_level() -> int:
	return upgrader.level

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

func _on_upgraded(upgrade: TurretUpgrade) -> void:
	if upgrade.max_health_bonus != 0:
		health.increase_max_health(upgrade.max_health_bonus)
	if upgrade.damage_bonus != 0:
		apply_damage_upgrade(upgrade.damage_bonus)
	health_ui.set_level(upgrader.level)
	if upgrader.is_max_level():
		_on_maxed()

func _on_maxed() -> void:
	if _stops_targeting_player_when_maxed:
		_stop_targeting_player()

## Override: stop selecting the player as a target. Attacks may still hit the player.
func _stop_targeting_player() -> void:
	pass

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
	range_indicator.show_indicator()

func _on_player_exited() -> void:
	range_indicator.hide_indicator()

## Subclasses overriding _physics_process must call super._physics_process(delta).
func _physics_process(delta: float) -> void:
	_update_repair(delta)

func _update_repair(delta: float) -> void:
	if _can_hold_repair(delta):
		if not _repairing:
			_repairing = true
			# Pauses turret behavior; resumed in _stop_repairing().
			_on_combat_stopped()
		repair.try_repair(delta, player.capacity.get_current())
		animation.play_animation("repair")
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
	animation.stop_animation("repair")
	if is_turret_active():
		_on_combat_started()

func _on_combat_started() -> void:
	pass

func _on_combat_stopped() -> void:
	pass

func is_turret_active() -> bool:
	return _active and enabled and not is_dead() and not _repairing

func was_hit(amount: int, _knockback_force: float, _from_position: Vector2) -> void:
	if is_dead() or _selling:
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