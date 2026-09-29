extends RefCounted
class_name TurretStatValues

## Snapshot of the turret stats shown in the shop and upgrade panels.

var max_health: int
var damage: int
var attack_cooldown: float
var attack_range: float

static func from_stats(stats: TurretStats) -> TurretStatValues:
	var values := TurretStatValues.new()
	values.max_health = stats.max_health
	values.damage = stats.damage
	values.attack_cooldown = stats.attack_cooldown
	values.attack_range = stats.attack_range
	return values
