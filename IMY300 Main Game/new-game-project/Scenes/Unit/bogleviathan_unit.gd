@tool
class_name BogLeviathanUnit
extends Unit

# Swamp Vengeance: When this dies, spawn a 'Vengeful Bog' unit with attack/health equal to the number of enemy units
func on_death(_killer_unit: Unit = null) -> void:
	# Find the ForestBoard to handle spawning
	var forest_board = get_tree().get_first_node_in_group("forestboard")
	if not forest_board:
		# Fallback: try to find it by type
		forest_board = get_node("/root").find_children("*", "ForestBoard", true, false)
		if forest_board.size() > 0:
			forest_board = forest_board[0]
		else:
			forest_board = null
	
	if not forest_board:
		return
	
	# Find the player area (where this unit was)
	var player_area = null
	if forest_board.has_method("get_player_area"):
		player_area = forest_board.get_player_area()
	else:
		# Try to find player area by name or group
		player_area = get_tree().get_first_node_in_group("player_area")
		if not player_area:
			var play_areas = get_tree().get_nodes_in_group("play_areas")
			for area in play_areas:
				if area.name.to_lower().contains("player"):
					player_area = area
					break
	
	if not player_area:
		return
	
	# Count living enemy units
	var enemy_area = null
	if forest_board.has_method("get_enemy_area"):
		enemy_area = forest_board.get_enemy_area()
	else:
		# Try to find enemy area
		enemy_area = get_tree().get_first_node_in_group("enemy_area")
		if not enemy_area:
			var play_areas = get_tree().get_nodes_in_group("play_areas")
			for area in play_areas:
				if area.name.to_lower().contains("enemy"):
					enemy_area = area
					break
	
	if not enemy_area:
		return
	
	var enemy_count = 0
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			enemy_count += 1
	
	# Only spawn if there are enemies (no point spawning a 0/0)
	if enemy_count > 0:
		_spawn_vengeful_bog(player_area, enemy_count, forest_board)

func _spawn_vengeful_bog(player_area: PlayArea, stats_value: int, forest_board) -> void:
	# Load the Vengeful Bog stats
	var vengeful_bog_stats = preload("res://data/units/spawned/vengeful_bog.tres")
	if not vengeful_bog_stats:
		return
	
	# Create a copy of the stats and modify attack/health
	var spawn_stats = vengeful_bog_stats.duplicate()
	spawn_stats.attack = stats_value
	spawn_stats.health = stats_value
	spawn_stats.base_attack = stats_value
	spawn_stats.base_health = stats_value
	
	# Find an empty spot in the player area
	var spawn_position = _find_empty_position(player_area)
	if spawn_position == Vector2(-1, -1):
		return  # No empty spots
	
	# Spawn the unit
	if forest_board.has_method("spawn_unit_at_position"):
		forest_board.spawn_unit_at_position(spawn_stats, spawn_position, player_area)
	elif player_area.has_method("spawn_unit"):
		player_area.spawn_unit(spawn_stats, spawn_position)

func _find_empty_position(play_area: PlayArea) -> Vector2:
	# Look for an empty position in the unit grid
	if not play_area or not play_area.unit_grid:
		return Vector2(-1, -1)
	
	# Check each position for an empty spot
	for row in range(play_area.unit_grid.rows):
		for col in range(play_area.unit_grid.columns):
			var pos = Vector2(col, row)
			if not play_area.unit_grid.units.has(pos) or play_area.unit_grid.units[pos] == null:
				return pos
	
	return Vector2(-1, -1)  # No empty spots found