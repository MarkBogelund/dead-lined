extends Orb
class_name CrunchPowerup

## Crunch Time charge. Once collected it trails the player until the charge is spent or lost.

@export var settings: CrunchPowerupSettings

@onready var visuals: Node2D = $Visuals
@onready var light: PointLight2D = $Visuals/PointLight2D
@onready var hit_particles: GPUParticles2D = $HitParticles

var _carrier: Player
var _follow_position := Vector2.ZERO
var _trail_direction := Vector2.LEFT
var _bob_time := 0.0

func _ready() -> void:
	if not settings:
		push_error("CrunchPowerup requires a CrunchPowerupSettings resource")
		return
	lifetime = settings.lifetime
	# Scaled on the parent because the orb animations key the sprite and light scales directly.
	visuals.scale = Vector2.ONE * settings.visual_scale
	light.color = settings.light_color
	light.energy = settings.light_energy
	super()
	set_physics_process(false)

## The round ending clears a carried charge via the player; this covers the one still on the ground.
func _connect_phase_signals(wave_manager: WaveManager) -> void:
	wave_manager.build_phase_started.connect(_on_despawn_phase)

func _try_collect(player: Player) -> bool:
	return player.try_collect_crunch_powerup()

func _on_collected(player: Player) -> void:
	_carrier = player
	_carrier.crunch_time.charge_spent.connect(_on_charge_spent, CONNECT_ONE_SHOT)
	_carrier.crunch_time.charge_lost.connect(_on_charge_lost, CONNECT_ONE_SHOT)
	freeze = true
	$CollisionShape2D.set_deferred("disabled", true)
	detection_area.set_deferred("monitoring", false)
	hit_particles.restart()
	_follow_position = global_position
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _carrier.velocity.length() > 1.0:
		_trail_direction = -_carrier.velocity.normalized()
	var target := _carrier.global_position + _trail_direction * settings.follow_distance
	_follow_position = _follow_position.lerp(target, 1.0 - exp(-settings.follow_smoothing * delta))
	_bob_time += delta
	global_position = _follow_position + Vector2.UP * sin(_bob_time * TAU * settings.bob_speed) * settings.bob_amplitude

func _on_charge_spent() -> void:
	_release()
	animation_handler.play_animation("pick_up")

func _on_charge_lost() -> void:
	_release()
	animation_handler.play_animation("despawn")

func _release() -> void:
	set_physics_process(false)
	if _carrier.crunch_time.charge_spent.is_connected(_on_charge_spent):
		_carrier.crunch_time.charge_spent.disconnect(_on_charge_spent)
	if _carrier.crunch_time.charge_lost.is_connected(_on_charge_lost):
		_carrier.crunch_time.charge_lost.disconnect(_on_charge_lost)
