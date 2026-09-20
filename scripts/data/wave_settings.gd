extends Resource
class_name WaveSettings

@export_group("Phase Timing")
## Duration of each build phase in seconds.
@export var build_phase_duration: float = 10.0
## Combat duration for wave one in seconds.
@export var base_combat_duration: float = 60.0
## Additional combat seconds added for each wave after wave one.
@export var combat_duration_growth: float = 5.0