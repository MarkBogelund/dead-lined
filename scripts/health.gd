extends Node
class_name HealthComponent

# Health
@export var max_health: int
var current_health: int

# Optional references for visuals
@export var animator_path: NodePath  # Can be AnimatedSprite2D or AnimationPlayer
var animator: Node = null

# Signals
signal died
signal damaged(amount)

func _ready():
	current_health = max_health

	animator = get_node_or_null(animator_path)
	if animator == null:
		push_error("Animator path is invalid")
	elif not (animator is AnimatedSprite2D or animator is AnimationPlayer):
		push_error("Animator must be AnimatedSprite2D or AnimationPlayer")

	if current_health <= 0:
		die()

# Call this to deal damage
func take_damage(amount: int) -> void:
	current_health -= amount
	emit_signal("damaged", amount)
	check_and_play_anim("hit")
	print(get_parent().name + " took damage")
	
	if current_health <= 0:
		die()

func check_and_play_anim(anim_name: String):
	if animator == null:
		return
	
	if animator is AnimatedSprite2D:
		if animator.sprite_frames.has_animation(anim_name):
			animator.animation = anim_name
			animator.play()
	elif animator is AnimationPlayer:
		if animator.has_animation(anim_name):
			animator.play(anim_name)

# Call this when health reaches zero
func die() -> void:
	current_health = 0
	emit_signal("died")
	print(get_parent().name + " died")
	check_and_play_anim("die")
