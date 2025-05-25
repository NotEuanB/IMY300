class_name ForestBoard
extends Node2D

@onready var unit_mover: UnitMover = $UnitMover
@onready var player_area: PlayArea = $PlayArea
@onready var hand_area: PlayArea = $HandArea
@onready var enemy_area: PlayArea = $EnemyArea
@export var player_stats: Resource

@export var enemy_stats: EnemyStats

func _ready() -> void:
	randomize()
	var states = GameState.load_state()
	var board_units = states[0]
	var hand_units = states[1]
	_spawn_units(board_units, player_area)
	_spawn_units(hand_units, hand_area)
	_spawn_enemy_units()
	_set_all_drag_and_drop_enabled(false)
	_set_all_units_enabled(false) 
	unit_mover.set_enabled(false)
	await get_tree().create_timer(3.0).timeout  # Add delay between turns
	start_combat()

func _spawn_units(units_data: Array, play_area: PlayArea) -> void:
	for unit_data in units_data:
		var stats = unit_data["stats"]
		var tile = unit_data["tile"]
		var unit_scene = stats.unit_scene if stats.unit_scene else preload("res://scenes/unit/unit.tscn")
		var unit = unit_scene.instantiate()
		play_area.unit_grid.add_child(unit)
		play_area.unit_grid.add_unit(tile, unit)
		unit.global_position = play_area.get_global_from_tile(tile)
		unit.stats = stats.duplicate()

func _spawn_enemy_units() -> void:
	for i in range(enemy_stats.units.size()):
		var unit_scene = enemy_stats.units[i]
		var tile = Vector2i(i, 0)
		var unit = unit_scene.instantiate()
		enemy_area.unit_grid.add_child(unit)
		enemy_area.unit_grid.add_unit(tile, unit)
		unit.global_position = enemy_area.get_global_from_tile(tile)
		if i < enemy_stats.unit_stats.size() and enemy_stats.unit_stats[i]:
			unit.stats = enemy_stats.unit_stats[i].duplicate()
		else:
			unit.stats = null

func get_living_unit_count(unit_grid) -> int:
	var count = 0
	for unit in unit_grid.units.values():
		if unit and unit.stats and unit.stats.health > 0:
			count += 1
	return count

func start_combat() -> void:
	while get_living_unit_count(player_area.unit_grid) > 0 and get_living_unit_count(enemy_area.unit_grid) > 0:		
		await _combat_round()

	# Determine the winner
	if get_living_unit_count(player_area.unit_grid) == 0:
		player_stats.health -= 2
		$Lose.play()
		print("Enemy wins!")
	elif get_living_unit_count(enemy_area.unit_grid) == 0:
		print("Player wins!")

func _player_turn() -> void:
	var living_player_tiles = []
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_player_tiles.append(tile)
	if living_player_tiles.size() == 0:
		return

	var player_tile = living_player_tiles[randi() % living_player_tiles.size()]
	var player_unit = player_area.unit_grid.units[player_tile]

	# Get all living enemy tiles
	var living_enemy_tiles = []
	for tile in enemy_area.unit_grid.units.keys():
		var unit = enemy_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_enemy_tiles.append(tile)
	if living_enemy_tiles.size() == 0:
		return

	var enemy_tile = living_enemy_tiles[randi() % living_enemy_tiles.size()]
	var enemy_unit = enemy_area.unit_grid.units[enemy_tile]

	_attack(player_unit, enemy_unit)

func _enemy_turn() -> void:
	# Get all living enemy tiles
	var living_enemy_tiles = []
	for tile in enemy_area.unit_grid.units.keys():
		var unit = enemy_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_enemy_tiles.append(tile)
	if living_enemy_tiles.size() == 0:
		return

	# Pick a random living enemy
	var enemy_tile = living_enemy_tiles[randi() % living_enemy_tiles.size()]
	var enemy_unit = enemy_area.unit_grid.units[enemy_tile]

	# Get all living player tiles
	var living_player_tiles = []
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_player_tiles.append(tile)
	if living_player_tiles.size() == 0:
		return  # No players left

	# Pick a random living player
	var player_tile = living_player_tiles[randi() % living_player_tiles.size()]
	var player_unit = player_area.unit_grid.units[player_tile]

	# Perform attack
	_attack(enemy_unit, player_unit)

func _attack(attacker, defender) -> void:
	if attacker == null or defender == null:
		return
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var original_pos = attacker.global_position
	var target_pos = defender.global_position
	var original_z = attacker.z_index

	# Bring attacker to front
	attacker.z_index = defender.z_index + 1

	# Animate attacker moving to defender
	var tween = create_tween()
	tween.tween_property(attacker, "global_position", target_pos, 0.5)
	await tween.finished

	# Both units deal damage to each other
	defender.stats.health -= attacker.stats.attack
	attacker.stats.health -= defender.stats.attack
	_update_health_display(defender)
	_update_health_display(attacker)
	print("%s attacks %s for %d damage! %s counterattacks for %d damage!" % [
		attacker.stats.name, defender.stats.name, attacker.stats.attack,
		defender.stats.name, defender.stats.attack
	])

	# Animate attacker moving back to original position
	var tween_back = create_tween()
	tween_back.tween_property(attacker, "global_position", original_pos, 0.5)
	await tween_back.finished

	# Restore original z_index
	attacker.z_index = original_z

	# Remove defender if dead
	if defender.stats.health <= 0:
		if defender in player_area.unit_grid.units.values():
			var tile = player_area.unit_grid.units.keys()[player_area.unit_grid.units.values().find(defender)]
			player_area.unit_grid.remove_unit(tile)
		elif defender in enemy_area.unit_grid.units.values():
			var tile = enemy_area.unit_grid.units.keys()[enemy_area.unit_grid.units.values().find(defender)]
			enemy_area.unit_grid.remove_unit(tile)
		defender.queue_free()
	# Remove attacker if dead (from counterattack)
	if attacker.stats.health <= 0:
		if attacker in player_area.unit_grid.units.values():
			var tile = player_area.unit_grid.units.keys()[player_area.unit_grid.units.values().find(attacker)]
			player_area.unit_grid.remove_unit(tile)
		elif attacker in enemy_area.unit_grid.units.values():
			var tile = enemy_area.unit_grid.units.keys()[enemy_area.unit_grid.units.values().find(attacker)]
			enemy_area.unit_grid.remove_unit(tile)
		attacker.queue_free()
	$Attack.play()

func _update_health_display(unit):
	if unit.has_node("Stats/HealthStat"):
		unit.get_node("Stats/HealthStat").text = str(unit.stats.health)

func _set_all_units_enabled(enabled: bool) -> void:
	for unit in player_area.unit_grid.units.values():
		if unit and unit.has_method("set_enabled"):
			unit.set_enabled(enabled)
	for unit in hand_area.unit_grid.units.values():
		if unit and unit.has_method("set_enabled"):
			unit.set_enabled(enabled)
	for unit in enemy_area.unit_grid.units.values():
		if unit and unit.has_method("set_enabled"):
			unit.set_enabled(enabled)

func _set_all_drag_and_drop_enabled(enabled: bool) -> void:
	for unit in player_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled
	for unit in hand_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled
	for unit in enemy_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled

func _combat_round() -> void:
	var player_tiles := []
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			player_tiles.append(tile)
	player_tiles.sort_custom(func(a, b): return a.y < b.y if a.x == b.x else a.x < b.x)

	var enemy_tiles := []
	for tile in enemy_area.unit_grid.units.keys():
		var unit = enemy_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			enemy_tiles.append(tile)
	enemy_tiles.sort_custom(func(a, b): return a.y < b.y if a.x == b.x else a.x < b.x)

	var i = 0
	var j = 0
	while i < player_tiles.size() or j < enemy_tiles.size():
		# Player attacks
		if i < player_tiles.size() and enemy_tiles.size() > 0:
			var player_unit = player_area.unit_grid.units[player_tiles[i]]
			# Refresh living enemy tiles
			var living_enemy_tiles = []
			for tile in enemy_area.unit_grid.units.keys():
				var unit = enemy_area.unit_grid.units[tile]
				if unit and unit.stats and unit.stats.health > 0:
					living_enemy_tiles.append(tile)
			if living_enemy_tiles.size() == 0:
				break
			var enemy_tile = living_enemy_tiles[randi() % living_enemy_tiles.size()]
			var enemy_unit = enemy_area.unit_grid.units[enemy_tile]
			await _attack(player_unit, enemy_unit)
			await get_tree().create_timer(0.5).timeout
		i += 1

		# Enemy attacks
		if j < enemy_tiles.size() and player_tiles.size() > 0:
			var enemy_unit = enemy_area.unit_grid.units[enemy_tiles[j]]
			# Refresh living player tiles
			var living_player_tiles = []
			for tile in player_area.unit_grid.units.keys():
				var unit = player_area.unit_grid.units[tile]
				if unit and unit.stats and unit.stats.health > 0:
					living_player_tiles.append(tile)
			if living_player_tiles.size() == 0:
				break
			var player_tile = living_player_tiles[randi() % living_player_tiles.size()]
			var player_unit = player_area.unit_grid.units[player_tile]
			await _attack(enemy_unit, player_unit)
			await get_tree().create_timer(0.5).timeout
		j += 1
