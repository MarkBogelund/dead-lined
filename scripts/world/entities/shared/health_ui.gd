extends Node2D
class_name HealthUIComponent

## Displays health as text above an entity
## Automatically updates when health changes
## Can be configured to show/hide when at full health

@export var health_component: HealthComponent
@export var offset := Vector2(0, -40) ## Position offset from parent entity
@export var show_when_full := false ## Show UI even at full health

@onready var label: Label = $Label

func _ready() -> void:
	position = offset
	
	if label:
		# Center the label
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_update_display()

func _process(_delta: float) -> void:
	# Poll for health changes each frame
	# Could be optimized with signals if HealthComponent emits health_changed signal
	_update_display()

func _update_display() -> void:
	if not health_component or not label:
		visible = false
		return
	
	var current := health_component.get_current_health()
	var max_hp := health_component.max_health
	
	label.text = "%d/%d" % [current, max_hp]
	
	# Only show when damaged (unless show_when_full is true)
	visible = show_when_full or current < max_hp
