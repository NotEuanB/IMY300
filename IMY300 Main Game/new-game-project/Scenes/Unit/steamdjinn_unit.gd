@tool
class_name SteamDjinnUnit
extends Unit

# Steam Cleave: When attacking, also deal damage to an additional adjacent enemy

func _ready() -> void:
	super._ready()
	# Mark this unit as having steam cleave ability
	call_deferred("_setup_cleave_metadata")

func _setup_cleave_metadata():
	# Wait for stats to be properly set, then add metadata
	if stats:
		stats.set_meta("has_steam_cleave", true)
		print("Steam Djinn: Cleave ability activated for ", stats.name)
		print("Steam Djinn: Metadata set successfully: ", stats.has_meta("has_steam_cleave"))
	else:
		# Try again next frame if stats aren't ready
		call_deferred("_setup_cleave_metadata")

func _check_stats_later():
	if stats:
		stats.set_meta("has_steam_cleave", true)
		print("Steam Djinn: Cleave ability activated (deferred) for ", stats.name)

# Override set_stats to ensure metadata persists
func set_stats(new_stats: Resource) -> void:
	super.set_stats(new_stats)
	# Re-apply the steam cleave metadata after stats are set
	if stats:
		stats.set_meta("has_steam_cleave", true)
		print("Steam Djinn: Metadata re-applied after stats update for ", stats.name)

# Apply cleave damage to adjacent enemies after primary combat
func apply_cleave_damage(primary_target: Unit, target_play_area: PlayArea) -> void:
	if not primary_target or not primary_target.stats or not target_play_area:
		print("Steam Djinn: Invalid parameters for cleave damage")
		return
	
	print("Steam Djinn: Steam Cleave activated against ", primary_target.stats.name)
	
	# Find adjacent enemies to the primary target for cleave damage
	var cleave_targets = _find_adjacent_enemies(primary_target, target_play_area)
	
	if cleave_targets.size() > 0:
		# Choose one random adjacent enemy for cleave (to keep it balanced)
		var cleave_target = cleave_targets[randi() % cleave_targets.size()]
		
		# Deal cleave damage (same as this unit's attack)
		_deal_cleave_damage(cleave_target, stats.attack)
		print("Steam Djinn: Cleaved ", cleave_target.stats.name, " for ", stats.attack, " damage")
	else:
		print("Steam Djinn: No adjacent targets found for cleave")

func _find_adjacent_enemies(primary_target: Unit, play_area: PlayArea) -> Array:
	var adjacent_enemies: Array = []
	
	if not play_area or not play_area.unit_grid:
		print("Steam Djinn: No play area or unit grid found")
		return adjacent_enemies
	
	# Find the primary target's position
	var target_position = Vector2i(-1, -1)
	for pos in play_area.unit_grid.units:
		if play_area.unit_grid.units[pos] == primary_target:
			target_position = pos
			break
	
	if target_position == Vector2i(-1, -1):
		print("Steam Djinn: Could not find primary target position")
		return adjacent_enemies
	
	print("Steam Djinn: Primary target at position ", target_position)
	
	# Check adjacent positions (8 directions)
	var adjacent_positions = [
		Vector2i(target_position.x - 1, target_position.y - 1),
		Vector2i(target_position.x, target_position.y - 1),
		Vector2i(target_position.x + 1, target_position.y - 1),
		Vector2i(target_position.x - 1, target_position.y),
		Vector2i(target_position.x + 1, target_position.y),
		Vector2i(target_position.x - 1, target_position.y + 1),
		Vector2i(target_position.x, target_position.y + 1),
		Vector2i(target_position.x + 1, target_position.y + 1)
	]
	
	for pos in adjacent_positions:
		if play_area.unit_grid.units.has(pos):
			var unit = play_area.unit_grid.units[pos]
			if unit and unit != primary_target and unit.stats and unit.stats.health > 0:
				adjacent_enemies.append(unit)
				print("Steam Djinn: Found adjacent enemy ", unit.stats.name, " at ", pos)
	
	print("Steam Djinn: Found ", adjacent_enemies.size(), " adjacent enemies")
	return adjacent_enemies

func _deal_cleave_damage(target: Unit, damage: int) -> void:
	if not target or not target.stats or target.stats.health <= 0:
		return
	
	print("Steam Djinn: Dealing ", damage, " cleave damage to ", target.stats.name)
	
	# Check for Coral Colossus immunity before applying cleave damage
	damage = _apply_coral_aegis_immunity(target, damage)
	
	# Apply cleave damage if not negated by immunity
	if damage > 0:
		target.stats.health -= damage
		target.set_stats(target.stats)
		
		# Update display if the method exists
		if target.has_method("_update_health_display"):
			target._update_health_display()
		
		print("Steam Djinn: ", target.stats.name, " now has ", target.stats.health, " health after cleave")
		
		# If unit died from cleave, queue death handling for next frame
		if target.stats.health <= 0:
			call_deferred("_handle_cleave_death_safely", target)

func _handle_cleave_death_safely(dead_unit: Unit) -> void:
	if not dead_unit or not is_instance_valid(dead_unit):
		return
		
	print("Steam Djinn: Handling cleave death for ", dead_unit.stats.name if dead_unit.stats else "unknown unit")
	
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
		print("Coral Colossus: ", unit.stats.name, " ignored cleave damage of ", damage, "!")
		# Remove the immunity (first instance only)
		unit.stats.remove_meta("coral_first_damage_immunity")
		# Ignore this damage
		return 0
	
	# Normal damage
	return damage
