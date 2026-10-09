extends Control
class_name BlueprintUnlockedNotification

## Placeholder pop-up shown when a blueprint unlocks a turret. The `show` clip owns all timing and visibility.

const SHOW_ANIMATION := &"show"

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false

func show_unlock(entry: TurretEntry) -> void:
	label.text = "NEW BLUEPRINT UNLOCKED\n%s" % entry.name.to_upper()
	label.pivot_offset = label.size / 2.0
	animation_player.stop()
	animation_player.play(SHOW_ANIMATION)
