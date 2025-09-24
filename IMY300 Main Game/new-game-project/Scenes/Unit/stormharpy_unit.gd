@tool
class_name StormHarpyUnit
extends Unit

# Storm Strike: At the start of combat, deal 2 damage to the weakest enemy unit
func on_combat_start(enemy_area: PlayArea, _player_area: PlayArea = null) -> void:
	# Find all living enemy units
	var enemies: Array = []
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			enemies.append(unit)
	
	if enemies.size() > 0:
		# Find the weakest enemy (lowest health)
		var weakest_enemy = enemies[0]
		for enemy in enemies:
			if enemy.stats.health < weakest_enemy.stats.health:
				weakest_enemy = enemy
		
		# Deal 2 damage to the weakest enemy
		_deal_damage_to_unit(weakest_enemy, 2)

func _deal_damage_to_unit(target: Unit, damage: int) -> void:
	if not target or not target.stats or target.stats.health <= 0:
		return
	
	# Check for Coral Colossus immunity before applying damage
	damage = _apply_coral_aegis_immunity(target, damage)
	
	# Apply damage
	target.stats.health -= damage
	target.set_stats(target.stats)
	
	# Update display if the method exists
	if target.has_method("_update_health_display"):
		target._update_health_display()
	
	# If unit died, queue death handling for next frame to avoid conflicts
	if target.stats.health <= 0:
		call_deferred("_handle_unit_death_safely", target)

func _handle_unit_death_safely(dead_unit: Unit) -> void:
	if not dead_unit or not is_instance_valid(dead_unit):
		return
		
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
		forest_board._handle_unit_death(dead_unit, self)

# Apply Coral Colossus immunity to damage calculation
func _apply_coral_aegis_immunity(unit: Unit, damage: int) -> int:
	if not unit or not unit.stats:
		return damage
	
	# Check if this unit has first damage immunity and hasn't used it yet
	if unit.stats.has_meta("coral_first_damage_immunity"):
		print("Coral Colossus: ", unit.stats.name, " ignored first instance of ", damage, " damage!")
		# Remove the immunity (first instance only)
		unit.stats.remove_meta("coral_first_damage_immunity")
		# Ignore this damage
		return 0
	
	# Normal damage
	return damage
