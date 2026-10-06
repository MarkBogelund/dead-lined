extends EnemyStats
class_name BulwarkStats

@export_group("Bulwark Armor")
## Maximum facing change in degrees per second; knockback pauses turning.
@export_range(1.0, 360.0, 1.0) var turn_speed_degrees := 60.0
## Total angle covered by the frontal armor, centered on its facing direction.
@export_range(1.0, 180.0, 1.0) var armor_arc_degrees := 120.0
## Fraction of incoming frontal damage removed while armored.
@export_range(0.0, 0.95, 0.01) var frontal_damage_reduction := 0.75
## Incoming frontal damage, before reduction, needed to break the armor.
@export_range(1.0, 500.0, 1.0) var stress_threshold := 30.0
## Seconds without frontal hits before stress starts to decay.
@export_range(0.0, 10.0, 0.05) var stress_decay_delay := 1.0
## Stress removed per second after the quiet period.
@export_range(0.0, 100.0, 0.5) var stress_decay_per_second := 5.0
## Seconds of unrestricted incoming damage before armor reforms.
@export_range(0.05, 30.0, 0.05) var armor_broken_duration := 4.0