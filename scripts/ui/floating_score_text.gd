extends Control
class_name FloatingScoreText

## Emitted when a floating label reaches its target
signal arrived

## The Control node that labels fly toward (set in inspector)
@export var target: Control

## How far the label drifts before flying (positive = down)
@export var float_distance: float = 20.0
@export var float_duration: float = 0.3
@export var fly_duration: float = 0.5

@onready var _label_template: Label = $LabelTemplate


## Spawn a floating label at a world-space position.
## text: the string to display
## color: modulate color (e.g. Color.WHITE for score, Color.RED for damage)
## world_position: position in world space — converted to screen space internally
func spawn(text: String, color: Color, world_position: Vector2) -> void:
	var screen_pos := get_viewport().get_canvas_transform() * world_position

	var label := _label_template.duplicate() as Label
	label.text = text
	label.modulate = color
	label.position = screen_pos
	label.visible = true
	add_child(label)

	var float_target := screen_pos + Vector2(0, float_distance)
	var fly_target := target.global_position + target.size * 0.5 if is_instance_valid(target) else screen_pos

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "position", float_target, float_duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position", fly_target, fly_duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		arrived.emit()
		label.queue_free()
	)
