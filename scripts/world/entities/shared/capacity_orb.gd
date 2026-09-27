extends Orb
class_name CapacityOrb

## Regular orb: restores capacity when collected.

@export var value := 1

func _try_collect(player: Player) -> bool:
	if not player.can_pickup:
		return false
	player.pickup(value)
	return true
