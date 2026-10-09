@tool
extends Resource
class_name TurretEntry

enum Category {AREA_DENIAL, RANGED}

@export_group("Shop")
@export var name: String
## Run setup draws starting turrets per category (see ShopRosterSettings).
@export var category := Category.AREA_DENIAL
@export var icon: Texture2D
@export_group("Icon Generator")
@export var icon_source: TurretIconTexture

func generate_icon() -> void:
	if not icon_source:
		return
	var image := icon_source.bake_image()
	if not image:
		return
	icon = ImageTexture.create_from_image(image)
	emit_changed()

@export_group("Shop")
@export var price: int
@export var turret_scene: PackedScene
## The placed turret's stats; the placement preview shows its attack_range.
@export var stats: TurretStats

@export_group("Shop Colors")
## Gradient that fills the shop info panel outlines while this turret is highlighted.
@export var outline_start_color := Color(0.28, 0.70, 0.67)
@export var outline_end_color := Color(0.61, 0.85, 0.72)

@export_group("Placement Preview")
## Used by the placement ghost and applied to the placed turret's exclusion zone.
@export var exclusion_radius: float = 80.0
