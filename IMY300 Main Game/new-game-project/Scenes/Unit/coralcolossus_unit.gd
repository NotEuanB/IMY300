@tool
class_name CoralColossusUnit
extends Unit

# Coral Aegis: Aura: Adjacent allies ignore the first instance of damage they would take each combat

# Apply aura at the start of combat to refresh immunity
func on_combat_start(_enemy_area: PlayArea, _player_area: PlayArea = null) -> void:
	_apply_coral_aegis_aura()

# Apply aura when this unit is played/placed on the board
func on_played(_play_area: PlayArea) -> void:
	_apply_coral_aegis_aura()

# Override set_stats to auto-apply aura when stats are loaded/set
func set_stats(value: Resource) -> void:
	super.set_stats(value)
	
	# Apply aura after a frame to ensure all units are ready
	if is_inside_tree():
		call_deferred("_apply_coral_aegis_aura")

func _apply_coral_aegis_aura() -> void:
	if not stats or not is_inside_tree():
		return
	
	print("Coral Colossus: Applying Coral Aegis aura...")
	
	# Find all adjacent units and grant them first damage immunity
	var adjacent_units = _get_adjacent_units()
	print("Coral Colossus: Found ", adjacent_units.size(), " adjacent units")
	
	for unit in adjacent_units:
		_grant_first_damage_immunity(unit)

func _get_adjacent_units() -> Array:
	var adjacent_units: Array = []
	
	# Find the play area this unit belongs to (use same approach as Golem)
	var play_area = null
	var current_parent = get_parent()
	while current_parent != null:
		if current_parent.has_method("get_unit_grid") or ("unit_grid" in current_parent and current_parent.unit_grid != null):
			play_area = current_parent
			break
		current_parent = current_parent.get_parent()
	
	# Fallback: try to find it through the tree
	if not play_area:
		var all_play_areas = get_tree().get_nodes_in_group("play_areas")
		for area in all_play_areas:
			if area.area_type == "board" and area.unit_grid:
				# Check if this unit is in this area
				for pos in area.unit_grid.units:
					if area.unit_grid.units[pos] == self:
						play_area = area
						break
				if play_area:
					break
	
	if not play_area or not play_area.unit_grid:
		print("Coral Colossus: Could not find play area or unit grid")
		return adjacent_units
	
	print("Coral Colossus: Found play area: ", play_area.name if play_area.has_method("get") and "name" in play_area else "unnamed")
	
	# Find this unit's position in the grid (same as Golem approach)
	var my_position = Vector2i(-1, -1)
	for pos in play_area.unit_grid.units:
		if play_area.unit_grid.units[pos] == self:
			my_position = pos
			break
	
	if my_position == Vector2i(-1, -1):
		print("Coral Colossus: Could not find my position in grid")
		return adjacent_units
	
	print("Coral Colossus: My position is ", my_position)
	
	# Check all 8 adjacent positions
	var adjacent_positions = [
		Vector2i(my_position.x - 1, my_position.y - 1),
		Vector2i(my_position.x, my_position.y - 1),
		Vector2i(my_position.x + 1, my_position.y - 1),
		Vector2i(my_position.x - 1, my_position.y),
		Vector2i(my_position.x + 1, my_position.y),
		Vector2i(my_position.x - 1, my_position.y + 1),
		Vector2i(my_position.x, my_position.y + 1),
		Vector2i(my_position.x + 1, my_position.y + 1)
	]
	
	print("Coral Colossus: Checking positions: ", adjacent_positions)
	
	for pos in adjacent_positions:
		print("Coral Colossus: Checking position ", pos)
		if play_area.unit_grid.units.has(pos):
			var unit = play_area.unit_grid.units[pos]
			print("Coral Colossus: Found unit at ", pos, ": ", unit.stats.name if unit and unit.stats else "null")
			if unit and unit != self and unit.stats and unit.stats.health > 0:
				adjacent_units.append(unit)
		else:
			print("Coral Colossus: No unit at position ", pos)
	
	return adjacent_units

func _grant_first_damage_immunity(unit: Unit) -> void:
	if not unit or not unit.stats:
		return
	
	# Mark the unit as having first damage immunity from Coral Colossus
	if not unit.stats.has_meta("coral_first_damage_immunity"):
		unit.stats.set_meta("coral_first_damage_immunity", true)
		print("Coral Colossus: Granted immunity to ", unit.stats.name)
	else:
		print("Coral Colossus: ", unit.stats.name, " already has immunity")

# Function to be called when an adjacent unit takes damage
static func check_coral_aegis_immunity(unit: Unit, damage: int) -> int:
	if not unit or not unit.stats:
		return damage
	
	# Check if this unit has first damage immunity and hasn't used it yet
	if unit.stats.has_meta("coral_first_damage_immunity"):
		# Remove the immunity (first instance only)
		unit.stats.remove_meta("coral_first_damage_immunity")
		# Ignore this damage
		return 0
	
	# Normal damage
	return damage

# Clean up immunity when moving to a new scene
func _on_scene_changed() -> void:
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit and unit.stats and unit.stats.has_meta("coral_first_damage_immunity"):
			unit.stats.remove_meta("coral_first_damage_immunity")