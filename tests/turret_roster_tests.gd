extends Node

const POOL_PATHS := [
	"res://resources/turrets/seeker/seeker_shop_details.tres",
	"res://resources/turrets/piercer/piercer_shop_details.tres",
	"res://resources/turrets/missiler/missiler_shop_details.tres",
	"res://resources/turrets/linker/linker_shop_details.tres",
	"res://resources/turrets/shockwaver/shockwaver_shop_details.tres",
	"res://resources/turrets/repulsor/repulsor_shop_details.tres",
	"res://resources/turrets/attractor/attractor_shop_details.tres",
	"res://resources/turrets/beamer/beamer_shop_details.tres",
]

func _ready() -> void:
	_test_roster()
	_test_boss_die_drops_blueprint()
	await _test_blueprint_in_game()
	print("PASS: 2+2 category start, unique seeded roster, random unlocks until exhausted, boss_die requests a drop, one non-expiring blueprint per wave that unlocks a turret and shows the notification")
	get_tree().quit()

func _test_boss_die_drops_blueprint() -> void:
	var boss: Node = load("res://scenes/world/enemies/boss_enemy_base.tscn").instantiate()
	var die := (boss.get_node("AnimationHandler") as AnimationPlayer).get_animation(&"boss_die")
	var found := false
	for track in die.get_track_count():
		if die.track_get_type(track) != Animation.TYPE_METHOD:
			continue
		for key in die.track_get_key_count(track):
			if die.method_track_get_name(track, key) == &"emit_blueprint_drop":
				found = true
	assert(found)
	boss.free()

func _make_pool() -> Array[TurretEntry]:
	var pool: Array[TurretEntry] = []
	for path: String in POOL_PATHS:
		pool.append(load(path) as TurretEntry)
	return pool

func _test_roster() -> void:
	var pool := _make_pool()
	var ranged := pool.filter(func(e: TurretEntry) -> bool: return e.category == TurretEntry.Category.RANGED)
	assert(ranged.size() == 4, "seeker, piercer, missiler, linker are ranged")
	var settings := load("res://resources/turrets/shop_roster_settings.tres") as ShopRosterSettings
	for seed_value in range(1, 40):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var roster := TurretRoster.new(pool, settings.starting_counts, rng)
		assert(roster.unlocked.size() == 4 and roster.locked_count() == 4)
		var ranged_count := roster.unlocked.filter(func(e: TurretEntry) -> bool: return e.category == TurretEntry.Category.RANGED).size()
		assert(ranged_count == 2)
		var seen := {}
		for entry in roster.unlocked:
			assert(not seen.has(entry))
			seen[entry] = true
		var other_rng := RandomNumberGenerator.new()
		other_rng.seed = seed_value
		assert(TurretRoster.new(pool, settings.starting_counts, other_rng).unlocked == roster.unlocked)
		for i in 4:
			var unlocked := roster.unlock_random()
			assert(unlocked and not seen.has(unlocked) and roster.unlocked.back() == unlocked)
			seen[unlocked] = true
		assert(roster.unlock_random() == null and roster.unlocked.size() == 8)

func _test_blueprint_in_game() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var shop := game.get_node("Systems/ShopManager") as ShopManager
	var world := game.get_node("World")
	var player := game.get_node("%Player") as Player
	var notification := game.get_node("UI/BlueprintUnlockedNotification") as BlueprintUnlockedNotification
	assert(shop.get_unlocked_entries().size() == 4)
	var unlocked_signals: Array[TurretEntry] = []
	shop.turret_unlocked.connect(func(entry: TurretEntry) -> void: unlocked_signals.append(entry))
	var spawn_manager := game.get_node("Systems/SpawnManager") as SpawnManager
	var drop_position := player.global_position + Vector2(200, 0)
	spawn_manager.blueprint_drop_requested.emit(drop_position)
	spawn_manager.blueprint_drop_requested.emit(drop_position)
	var blueprints := world.get_children().filter(func(n: Node) -> bool: return n is Blueprint)
	assert(blueprints.size() == 1, "only one blueprint per wave")
	var blueprint := blueprints[0] as Blueprint
	assert(blueprint.lifetime <= 0.0)
	game.get_node("Systems/WaveManager").combat_phase_started.emit(2)
	await get_tree().create_timer(1.2).timeout
	assert(is_instance_valid(blueprint) and blueprint.can_collect, "blueprint survives phase changes")
	blueprint._on_body_entered(player)
	assert(unlocked_signals.is_empty() and shop.get_unlocked_entries().size() == 5)
	var unlocked_entry: TurretEntry = shop.get_unlocked_entries().back()
	assert(player.effects_animation.get_current_anim_name() == "blueprint_flash")
	assert(player.effects_animation.get_animation("blueprint_flash").find_track(NodePath("AnimatedSprite2D:self_modulate"), Animation.TYPE_VALUE) >= 0)
	await get_tree().create_timer(0.08).timeout
	assert(player.animated_sprite.self_modulate.b > player.animated_sprite.self_modulate.r)
	assert(not notification.visible)
	game.get_node("Systems/WaveManager").build_phase_started.emit()
	assert(unlocked_signals.size() == 1)
	assert(unlocked_signals[0] == unlocked_entry)
	await get_tree().create_timer(0.1).timeout
	assert(notification.visible and unlocked_signals[0].name.to_upper() in notification.label.text)
	await get_tree().create_timer(1.2).timeout
	assert(not is_instance_valid(blueprint))
	# combat_phase_started above reset the wave limit, so the next boss may drop again.
	spawn_manager.blueprint_drop_requested.emit(drop_position)
	assert(world.get_children().filter(func(n: Node) -> bool: return n is Blueprint).size() == 1)
	game.queue_free()
	await get_tree().process_frame
	assert(not MenuManager._entries.has(&"game_over"))
