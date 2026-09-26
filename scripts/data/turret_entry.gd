extends Resource
class_name TurretEntry

@export_group("Shop")
@export var name: String
@export var icon: Texture2D
@export var price: int
@export var turret_scene: PackedScene
@export var ghost_scene: PackedScene
@export var stats: Resource

@export_group("Placement Preview")
@export var preview_range: float = -1.0
## Used by the placement ghost and applied to the placed turret's exclusion zone.
@export var exclusion_radius: float = 80.0
