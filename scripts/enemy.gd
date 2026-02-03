extends CharacterBody2D

const speed := 100.0
const knockback_strength := 300.0
const knockback_friction := 1200.0  # How fast knockback slows down

var player: Node2D
var knockback_velocity := Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player == null:
		return

	# If the enemy is being knocked back, move according to knockback
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		# Normal chasing behavior
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
	
	move_and_slide()

# Call this when the enemy should be knocked back
func apply_knockback(from_position: Vector2, knockback_strength: float):
	var dir = (global_position - from_position).normalized()
	knockback_velocity = dir * knockback_strength

# Called when the hitbox detects a collision
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player hit!")
		# Knock the enemy back away from the player
		apply_knockback(body.global_position, knockback_strength)
		body.apply_knockback(global_position, 100)
