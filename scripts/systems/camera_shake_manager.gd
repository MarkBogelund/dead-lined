extends Node
class_name CameraShakeManager

## Manages camera shake effects for game events

@export var camera: Camera2D
@export var trauma_decay := 1.5 ## How fast shake recovers (higher = faster)
@export var max_offset := 50.0 ## Maximum pixel offset for shake
@export var max_rotation := 5.0 ## Maximum rotation in degrees (set to 0 to disable)

var trauma := 0.0 ## Current shake intensity (0.0 to 1.0)

func _ready() -> void:
	add_to_group("camera_shake_manager")

func _process(delta: float) -> void:
	if trauma > 0.0:
		# Decay trauma over time
		trauma = max(trauma - trauma_decay * delta, 0.0)
		
		# Calculate shake amount (square for smoother feel)
		var shake_amount := trauma * trauma
		
		# Apply random offset
		var offset_x := randf_range(-max_offset, max_offset) * shake_amount
		var offset_y := randf_range(-max_offset, max_offset) * shake_amount
		
		if camera:
			camera.offset = Vector2(offset_x, offset_y)
			
			# Optional rotation shake
			if max_rotation > 0:
				var rotation_amount := randf_range(-max_rotation, max_rotation) * shake_amount
				camera.rotation_degrees = rotation_amount
	else:
		# Reset camera to normal
		if camera:
			camera.offset = Vector2.ZERO
			camera.rotation_degrees = 0.0

## Public API - Call from anywhere to shake the screen
## intensity: How strong (0.0 to 1.0+, values > 1.0 will be very intense)
## duration: Ignored - decay rate controls duration (kept for API compatibility)
func shake_screen(intensity: float, _duration: float = 0.0) -> void:
	# Add trauma (clamped to 1.0 max)
	# The trauma_decay rate will naturally control how long it lasts
	trauma = min(trauma + intensity, 1.0)
