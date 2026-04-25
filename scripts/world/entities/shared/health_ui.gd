extends Node2D
class_name HealthUIComponent

## Displays health as text above an entity
## Automatically updates when health changes
## Can be configured to show/hide when at full health

@export var health_component: HealthComponent
@export var offset := Vector2(0, -40) ## Position offset from parent entity

@onready var label: Label = $Label

var _upgrade_open := false

func _ready() -> void:
	visible = false
	position = offset
	
	if label:
		# Center the label
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
	
	visible = not _upgrade_open

func set_upgrade_open(open: bool) -> void:
	_upgrade_open = open
