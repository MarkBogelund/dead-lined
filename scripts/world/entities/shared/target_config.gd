extends Resource
class_name TargetConfig

## Configuration for a single target priority level
## Used by TargetingComponent to determine what entities should be targeted

## The group name to search for targets (e.g., "player", "enemies", "turrets")
@export var group_name: String = ""

## Priority level - higher values have higher priority
@export var priority: int = 0
