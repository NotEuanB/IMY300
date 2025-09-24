@tool
class_name GolemUnit
extends Unit

var buffed_units: Array = []

func _ready() -> void:
	super._ready()
	# Clean up when this node exits the scene tree
	tree_exiting.connect(_cleanup_on_exit)

func _cleanup_on_exit():
	"""Clean up all aura effects when this Golem is removed from the scene"""
	print("Golem: Cleaning up on scene exit")
	_remove_aura()

# Override set_stats to auto-apply aura when stats are loaded/set
func set_stats(value: Resource) -> void:
	super.set_stats(value)
	
	# Auto-apply aura when stats are set (during loading or updates)
	call_deferred("_try_auto_apply_aura")

func _try_auto_apply_aura():
	"""Try to auto-apply aura if conditions are right"""
	if not stats:
		return
	
	# Try to find the play area by walking up the parent tree
	var current_parent = get_parent()
	var play_area = null
	
	# Look for a PlayArea in the parent hierarchy
	while current_parent != null:
		if current_parent.has_method("get_tile_from_global") and current_parent.has_method("is_tile_in_bounds"):
			play_area = current_parent
			break
		current_parent = current_parent.get_parent()
	
	if play_area:
		# Check if this is a board area (not hand area)
		var is_board_area = true
		if play_area.has_method("get") and play_area.get("area_type") == "hand":
			is_board_area = false
		elif play_area.name.to_lower().contains("hand"):
			is_board_area = false
			
		if is_board_area:
			print("Golem: Auto-applying aura after stats loaded for ", stats.name)
			update_aura(play_area)
		else:
			print("Golem: In hand area, skipping auto-aura")
	else:
		print("Golem: No play area found for auto-aura")

func update_aura(play_area: PlayArea) -> void:
	# Always remove existing aura first to prevent double-buffing
	_remove_aura()
	
	# Find this Golem's tile
	var my_tile: Vector2i = Vector2i(-1, -1)
	for tile in play_area.unit_grid.units.keys():
		if play_area.unit_grid.units[tile] == self:
			my_tile = tile
			break
	if my_tile == Vector2i(-1, -1):
		return
	
	# Buff only adjacent units (not self)
	var offsets = [
		Vector2i(-1, 0), Vector2i(1, 0)
	]
	for offset in offsets:
		var adj_tile = my_tile + offset
		if play_area.unit_grid.units.has(adj_tile):
			var adj_unit = play_area.unit_grid.units[adj_tile]
			if adj_unit != null and adj_unit != self:
				# Apply temporary aura buff that won't persist
				print("Golem: Applying +2/+2 aura to ", adj_unit.stats.name)
				_apply_aura_buff(adj_unit)
				buffed_units.append(adj_unit)

func _apply_aura_buff(unit) -> void:
	"""Apply aura buff using stored original values approach"""
	# Store original stats before applying buff (like Scoundrel's Deal does)
	if not unit.stats.has_meta("golem_original_attack"):
		unit.stats.set_meta("golem_original_attack", unit.stats.attack)
		unit.stats.set_meta("golem_original_health", unit.stats.health)
	
	# Apply the aura buff: +2 attack, +2 health
	unit.stats.attack += 2
	unit.stats.health += 2
	unit.set_stats(unit.stats)
	
	# Mark this unit as having golem aura active
	unit.stats.set_meta("golem_aura_active", true)

func _is_unit_already_buffed(unit) -> bool:
	# Check if this unit already has golem aura active
	return unit.stats.has_meta("golem_aura_active")

func _remove_aura() -> void:
	print("Golem: Removing aura from ", buffed_units.size(), " units")
	for unit in buffed_units:
		if unit and is_instance_valid(unit):
			if unit.stats.has_meta("golem_aura_active"):
				print("Golem: Restoring original stats for ", unit.stats.name)
				var original_attack = unit.stats.get_meta("golem_original_attack")
				var original_health = unit.stats.get_meta("golem_original_health")
				
				# Restore original stats
				unit.stats.attack = original_attack
				unit.stats.health = original_health
				
				# Clean up metadata
				unit.stats.remove_meta("golem_aura_active")
				unit.stats.remove_meta("golem_original_attack")
				unit.stats.remove_meta("golem_original_health")
				
				# Update display
				unit.set_stats(unit.stats)
				print("Golem: Restored ", unit.stats.name, " to ", unit.stats.attack, "/", unit.stats.health)
	
	buffed_units.clear()
	print("Golem: Aura removal complete")

func on_played(play_area: PlayArea) -> void:
	update_aura(play_area)

func on_removed_from_board(_play_area: PlayArea) -> void:
	_remove_aura()

# Note: Cleanup of persistent aura effects now happens during unit spawning
# in _spawn_units functions to prevent visual glitches
