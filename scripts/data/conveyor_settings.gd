extends Resource
class_name ConveyorSettings

## World-space speed used by spawn intro tweens and enemy conveyor movement.
@export_range(1.0, 1000.0, 1.0, "or_greater") var enemy_movement_speed := 120.0
## World-space speed added to player movement while standing on conveyor belts.
@export_range(0.0, 1000.0, 1.0, "or_greater") var player_movement_speed := 35.0
