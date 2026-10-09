extends RefCounted
class_name TurretRoster

## Which turrets the shop offers this run. Pure logic so it can be tested without a scene.

## Shop order: starting turrets first, then each unlock appended.
var unlocked: Array[TurretEntry] = []
var _locked: Array[TurretEntry] = []
var _rng: RandomNumberGenerator

func _init(pool: Array[TurretEntry], starting_counts: Dictionary[TurretEntry.Category, int], rng: RandomNumberGenerator) -> void:
	_rng = rng
	_locked = pool.duplicate()
	for category: TurretEntry.Category in starting_counts:
		var candidates := _locked.filter(func(entry: TurretEntry) -> bool: return entry.category == category)
		var wanted: int = starting_counts[category]
		if candidates.size() < wanted:
			push_warning("TurretRoster: only %d turrets in category %s, wanted %d" % [candidates.size(), TurretEntry.Category.find_key(category), wanted])
		for i in mini(wanted, candidates.size()):
			var picked: TurretEntry = candidates.pop_at(_rng.randi_range(0, candidates.size() - 1))
			_locked.erase(picked)
			unlocked.append(picked)
	_shuffle(unlocked)

func locked_count() -> int:
	return _locked.size()

## Moves one random locked turret into the shop; null when everything is unlocked.
func unlock_random() -> TurretEntry:
	if _locked.is_empty():
		return null
	var entry: TurretEntry = _locked.pop_at(_rng.randi_range(0, _locked.size() - 1))
	unlocked.append(entry)
	return entry

func _shuffle(entries: Array[TurretEntry]) -> void:
	for i in range(entries.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := entries[i]
		entries[i] = entries[j]
		entries[j] = swap
