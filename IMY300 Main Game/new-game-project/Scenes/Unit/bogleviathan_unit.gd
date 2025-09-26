@tool
class_name BogLeviathanUnit
extends Unit

# Swamp Vengeance: When this dies, deal 1 damage to all enemy units
func on_death(_killer_unit: Unit = null) -> void:
	# Find the ForestBoard to handle damage
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
	
	# Get enemy area
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
	
	# Deal 1 damage to all enemies
	print("Bogleviathan Swamp Vengeance: Dealing 1 damage to all enemies")
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			unit.take_damage(1, null)
			print("Swamp Vengeance damaged ", unit.stats.name, " for 1")