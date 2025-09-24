@tool
class_name AshwraithUnit
extends Unit

# Infernal Harvest: On play - Deal 1 damage to random enemy. Each time any unit dies this combat, gain +1 attack permanently
func on_played(_play_area: PlayArea) -> void:
	if stats.buff_used:
		return

	# Deal 1 damage to a random enemy (Flame Imp part)
	# Find enemy area through ForestBoard
	var forest_board = get_node("/root/ForestBoard")
	if forest_board and forest_board.has_node("EnemyArea"):
		var enemy_area = forest_board.get_node("EnemyArea")
		_deal_damage_to_random_enemy(enemy_area)
	
	# Mark buff as used (one-time use like Flame Imp)
	stats.buff_used = true
	
	# Mark this unit as having Infernal Harvest active for the rest of combat
	stats.set_meta("infernal_harvest_active", true)
	
	# Play buff sound effect
	if has_node("Buff"):
		$Buff.play()

# Called whenever any unit dies - this is where the harvest happens
func on_unit_death():
	if stats and stats.has_meta("infernal_harvest_active"):
		stats.attack += 1
		stats.base_attack += 1  # Make it permanent
		set_stats(stats)
		

		
		# Play harvest sound effect
		if has_node("Buff"):
			$Buff.play()

func _ready() -> void:
	super._ready()

# Deal damage to a random enemy (adapted from Flame Imp logic)
func _deal_damage_to_random_enemy(enemy_area: PlayArea):
	# Find all enemy units
	var enemies: Array = []
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			enemies.append(unit)
	
	if enemies.size() > 0:
		# Pick a random enemy
		var target = enemies[randi() % enemies.size()]
		
		# Check for Coral Colossus immunity before applying damage
		var damage = _apply_coral_aegis_immunity(target, 1)
		
		# Deal damage
		target.stats.health -= damage
		target.set_stats(target.stats)
		
		# Check if target died and handle removal
		if target.stats.health <= 0:
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

# Static function to reset Infernal Harvest after combat
static func reset_all_infernal_harvest(play_area: PlayArea):
	for unit in play_area.unit_grid.units.values():
		if unit != null and unit.stats.has_meta("infernal_harvest_active"):
			unit.stats.remove_meta("infernal_harvest_active")

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
