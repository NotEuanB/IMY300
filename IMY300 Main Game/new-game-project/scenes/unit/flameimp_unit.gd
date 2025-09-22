@tool
class_name FlameImpUnit
extends Unit

# Flame Burst: At the start of combat, deal 1 damage to a random enemy
func on_combat_start(enemy_area: PlayArea) -> void:
	if stats.buff_used:
		return
	
	# Find all enemy units
	var enemies: Array = []
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			enemies.append(unit)
	
	if enemies.size() > 0:
		# Pick a random enemy
		var target = enemies[randi() % enemies.size()]
		
		print("Flame Imp uses Flame Burst on ", target.stats.name, "!")
		
		# Deal 1 damage
		target.stats.health -= 1
		target.set_stats(target.stats)
		
		# Update display if the method exists
		if target.has_method("_update_health_display"):
			target._update_health_display()
		
		# Check if target died and handle removal
		if target.stats.health <= 0:
			print(target.stats.name + " was killed by Flame Burst!")
			# Find the ForestBoard to handle unit death properly
			var forest_board = get_tree().get_first_node_in_group("forestboard")
			if not forest_board:
				# Fallback: try to find it by type
				forest_board = get_node("/root").find_children("*", "ForestBoard", true, false)
				if forest_board.size() > 0:
					forest_board = forest_board[0]
				else:
					forest_board = null
			
			if forest_board and forest_board.has_method("_handle_unit_death"):
				forest_board._handle_unit_death(target, self)
			else:
				print("Warning: Could not find ForestBoard to handle unit death properly")
		
		stats.buff_used = true
		print("Flame Imp's Flame Burst activated! Target now has ", target.stats.health, " health.")
	else:
		print("Flame Imp found no enemies to target with Flame Burst")
