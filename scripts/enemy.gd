extends CharacterBody2D

const DAMAGE := 20

const SPEED := 50.0
const ENEMY_KNOCKBACK := 200.0
const PLAYER_KNOCKBACK := 100.0

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: Area2D = $Hitbox

var player: Node2D
var dead: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	health.connect("died", Callable(self, "_on_died"))

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# --- Movement ---
	if knockback.is_active():
		velocity = knockback.velocity
	elif dead:
		velocity = knockback.velocity if knockback.is_active() else Vector2.ZERO
	else:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * SPEED

	knockback.process(delta)
	move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if dead:
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
			
func _on_died():
	# Stop chasing but allow knockback
	dead = true

	# Disable hitbox so it cannot hit the player anymore
	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("monitoring", false)
