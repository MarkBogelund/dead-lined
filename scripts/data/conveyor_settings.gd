extends Resource
class_name ConveyorSettings

## Shared world-space speed used by both the spawn intro and conveyor belt.
@export_range(1.0, 1000.0, 1.0, "or_greater") var movement_speed := 120.0
