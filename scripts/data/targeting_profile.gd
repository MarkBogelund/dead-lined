extends Resource
class_name TargetingProfile

## Two-tier target selection rules for TargetingComponent. Distances are straight-line pixels.

## Group preferred by default (enemies: "player", turrets: "enemies"). Debug: blue circle = distance to nearest; blue line = targeted.
@export var high_priority_group: StringName = &"player"
## Fallback group; leave empty to only ever target the high-priority group. Debug: orange circle = distance to nearest; orange line = targeted.
@export var low_priority_group: StringName = &""
## A high-priority target within this distance always wins. -1 disables the lock. Debug: yellow circle.
@export var lock_radius: float = -1.0
## Switch to the low-priority target when dist(high) > dist(low) + this. Debug: red circle (high target outside it -> low target chosen).
@export var cross_priority_margin: float = 20.0
## While on the low-priority target, switch back when dist(high) < dist(low) + this. Keep <= cross_priority_margin. Debug: red circle while on the low target.
@export var cross_priority_return_margin: float = 0.0
## A same-priority challenger replaces the current target only when dist(challenger) + this < dist(current). Debug: green circle (challenger inside it takes over).
@export var same_priority_margin: float = 16.0

@export_group("Debug")
## Draws the decision distances on the ground around every entity using this profile. White circle = the component's max_range.
@export var debug_draw := false
