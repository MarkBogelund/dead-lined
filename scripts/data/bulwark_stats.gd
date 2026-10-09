extends EnemyStats
class_name BulwarkStats

@export_group("Shield")
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

@export_group("Shield Attacks")
@export_subgroup("Ram")
## Damage when the intact shield rams a player or turret; should outhit body contact.
@export_range(0, 200, 1) var shield_damage := 15
@export_range(0.0, 1000.0, 1.0) var shield_knockback := 350.0
## Self knockback when the shield rams a target, so Bulwark bounces off instead of pushing into it.
@export_range(0.0, 1000.0, 1.0) var shield_ram_recoil := 150.0
## Seconds after a ram before Bulwark advances to ram again.
@export_range(0.0, 10.0, 0.05) var shield_ram_cooldown := 1.0
## Center distance to the target where Bulwark holds while the ram cools down; just outside shield reach.
@export_range(0.0, 200.0, 1.0) var shield_ram_hold_distance := 52.0
## Closer than this (target inside the shield), Bulwark backs away until it reaches the hold distance; keep it below ram contact range.
@export_range(0.0, 200.0, 1.0) var shield_ram_min_distance := 36.0
@export_subgroup("Wave")
@export_range(0, 200, 1) var shield_wave_damage := 12
@export_range(0.0, 1000.0, 1.0) var shield_wave_knockback := 300.0
## Seconds between shield waves; only counts down while the shield is intact.
@export_range(0.5, 30.0, 0.1) var shield_wave_cooldown := 5.0
## The charge only starts when the target is within this distance.
@export_range(0.0, 1000.0, 1.0) var shield_wave_trigger_range := 220.0
## Distance the wave travels before it fades.
@export_range(10.0, 1000.0, 1.0) var shield_wave_range := 250.0
## Wave travel speed in pixels per second.
@export_range(10.0, 2000.0, 1.0) var shield_wave_speed := 420.0
## Hit band thickness of the wave.
@export_range(1.0, 64.0, 1.0) var shield_wave_width := 10.0
## Total angle of the wave, centered on the shield's facing.
@export_range(1.0, 360.0, 1.0) var shield_wave_arc_degrees := 100.0