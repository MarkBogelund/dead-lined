extends GridContainer
class_name TurretStatsView

## 2x2 grid of turret stats (health, damage, speed, range). Shared by the shop info panel and the upgrade panel.

## Color of a stat value that the previewed upgrade changes.
@export var preview_color := Color(0.45, 1.0, 0.45)

@onready var health_label: Label = %HealthLabel
@onready var damage_label: Label = %DamageLabel
@onready var speed_label: Label = %SpeedLabel
@onready var range_label: Label = %RangeLabel

## preview is the next level's stats; changed values show the new value in preview_color.
func show_stats(values: TurretStatValues, preview: TurretStatValues = null) -> void:
	_set_stat(health_label, str(values.max_health), str(preview.max_health) if preview else "")
	_set_stat(damage_label, str(values.damage), str(preview.damage) if preview else "")
	_set_stat(speed_label, _format_cooldown(values.attack_cooldown), _format_cooldown(preview.attack_cooldown) if preview else "")
	_set_stat(range_label, str(roundi(values.attack_range)), str(roundi(preview.attack_range)) if preview else "")

func _set_stat(value_label: Label, current: String, next: String) -> void:
	var changed := not next.is_empty() and next != current
	value_label.text = next if changed else current
	value_label.self_modulate = preview_color if changed else Color.WHITE

func _format_cooldown(seconds: float) -> String:
	return "%ss" % snappedf(seconds, 0.01)
