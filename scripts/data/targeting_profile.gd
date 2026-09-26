extends Resource
class_name TargetingProfile

## Two-group target selection rules for TargetingComponent. Distances are straight-line pixels.

## The group this entity prefers to target (enemies: player, turrets: enemies). Debug: blue.
@export var primary_group: StringName = &"player"
## The fallback group, used when the primary target is clearly farther away. Leave empty to never use one. Debug: orange.
@export var secondary_group: StringName = &""
## A primary target this close is always chosen, no matter where the secondary target is. -1 turns it off. Debug: yellow.
@export var primary_lock_radius: float = -1.0
## How much farther than the secondary target the primary target must be before the entity switches away from it. Debug: red.
@export var switch_to_secondary_margin: float = 20.0
## How much farther than the secondary target the primary target may still be when the entity switches back to it.
## Keep it at or below the switch margin so the entity doesn't flip back and forth. Debug: purple.
@export var return_to_primary_margin: float = 0.0
## How much closer another target in the same group must be before the entity drops its current target for it. Debug: green.
@export var retarget_margin: float = 16.0

@export_group("Debug")
## White circle: the component's max range.
@export var debug_max_range := false
## Yellow circle: the primary lock radius.
@export var debug_lock_radius := false
## Blue circle: distance to the nearest primary target.
@export var debug_primary_distance := false
## Orange circle: distance to the nearest secondary target.
@export var debug_secondary_distance := false
## Red circle: the primary target leaving this circle makes the entity switch to the secondary target.
@export var debug_switch_ring := false
## Purple circle: the primary target entering this circle brings the entity back to it.
@export var debug_return_ring := false
## Green circle: another same-group target entering this circle takes over as the target.
@export var debug_retarget_ring := false
## Line to the current target, blue when primary and orange when secondary.
@export var debug_target_line := false

func is_debug_enabled() -> bool:
	return debug_max_range or debug_lock_radius or debug_primary_distance or debug_secondary_distance \
		or debug_switch_ring or debug_return_ring or debug_retarget_ring or debug_target_line
