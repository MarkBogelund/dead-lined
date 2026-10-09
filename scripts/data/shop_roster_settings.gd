extends Resource
class_name ShopRosterSettings

## Per-run shop setup: which turrets the shop starts with and how blueprints unlock more.

## Starting turrets drawn at random per category; the rest are unlocked by blueprints.
@export var starting_counts: Dictionary[TurretEntry.Category, int] = {
	TurretEntry.Category.AREA_DENIAL: 2,
	TurretEntry.Category.RANGED: 2,
}
## Pickup a boss drops; collecting it unlocks one random locked turret.
@export var blueprint_scene: PackedScene
## Upper bound on blueprints dropped per wave, however many bosses die in it.
@export_range(0, 10, 1) var max_blueprints_per_wave := 1
## Non-zero makes runs repeatable (tests, debugging); zero randomizes every run.
@export var random_seed := 0
