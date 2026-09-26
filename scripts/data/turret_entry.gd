extends Resource
class_name TurretEntry

@export_group("Shop")
@export var name: String
@export var icon: Texture2D
@export var price: int
@export var turret_scene: PackedScene
@export var ghost_scene: PackedScene
## The placed turret's stats; the placement preview shows its attack_range.
@export var stats: TurretStats

@export_group("Placement Preview")
## Used by the placement ghost and applied to the placed turret's exclusion zone.
@export var exclusion_radius: float = 80.0
