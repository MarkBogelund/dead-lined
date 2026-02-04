extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const DAMAGE := 20

const SPEED := 50.0
const ENEMY_KNOCKBACK := 200.0
const PLAYER_KNOCKBACK := 100.0

const SEPARATION_RADIUS := 40.0      # how close enemies can get
const SEPARATION_FORCE := 120.0      # how strongly they push apart

var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	health.connect("died", Callable(self, "_on_died"))
	health.connect("damaged", Callable(self, "_on_damaged"))

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# --- Movement ---
	if knockback.is_active():
		velocity = knockback.velocity
	elif health.is_dead:
		velocity = knockback.velocity if knockback.is_active() else Vector2.ZERO
	else:
		var chase_dir := (player.global_position - global_position).normalized()
		var separation_dir := get_separation_vector()

		var separation := get_separation_vector() * SEPARATION_FORCE
		var desired_velocity := chase_dir * SPEED + separation

		# Clamp to max speed
		if desired_velocity.length() > SPEED:
			desired_velocity = desired_velocity.normalized() * SPEED

		velocity = desired_velocity


	knockback.process(delta)
	move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if health.is_dead:
		return

	if body.is_in_group("player"):
		health.take_damage(DAMAGE)
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)

		knockback.apply(body.global_position, ENEMY_KNOCKBACK)
		if body.has_method("apply_knockback"):
			body.apply_knockback(global_position, PLAYER_KNOCKBACK)

func apply_knockback(from_position: Vector2, strength: float = 300.0):
	knockback.apply(from_position, strength)
	
func take_damage(amount: int):
	health.take_damage(amount)
	if not health.is_dead:
		check_and_play_anim("take_damage")
			
func _on_died():
	collision_shape.set_deferred("disabled", true)
	hitbox_collision_shape.set_deferred("disabled", true)
	check_and_play_anim("die")
	
func check_and_play_anim(anim_name: String):
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("Animation \"" + anim_name + "\" does not exist")

func get_separation_vector() -> Vector2:
	var push := Vector2.ZERO
	var enemies := get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == self:
			continue
		if enemy.health.is_dead:
			continue

		var offset: Vector2 = global_position - enemy.global_position
		var dist := offset.length()

		if dist > 0.0 and dist < SEPARATION_RADIUS:
			# Weight by proximity (closer = stronger)
			var strength := (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS
			push += offset.normalized() * strength

	return push
