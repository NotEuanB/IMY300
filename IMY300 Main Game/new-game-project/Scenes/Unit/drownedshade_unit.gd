@tool
class_name DrownedShadeUnit
extends Unit

# Tidal Haunting: At the start of combat, reduce all enemy attacks by 1 (minimum 1), gain +1 attack for each enemy affected
func on_combat_start(enemy_area: PlayArea, _player_area: PlayArea = null) -> void:
	var enemies_affected = 0
	
	print("Drowned Shade: Tidal Haunting activated!")
	
	# Find all enemy units and reduce their attack by 1
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			var original_attack = unit.stats.attack
			
			# Store original attack for display purposes (like Tide Serpent)
			if not unit.stats.has_meta("drownedshade_original_attack"):
				unit.stats.set_meta("drownedshade_original_attack", original_attack)
			
			# Reduce attack by 1 (minimum 1)
			unit.stats.attack = max(1, unit.stats.attack - 1)
			
			# Only count as "affected" if we actually reduced their attack
			if unit.stats.attack < original_attack:
				enemies_affected += 1
				print("Drowned Shade: Reduced ", unit.stats.name, " attack from ", original_attack, " to ", unit.stats.attack)
			
			unit.set_stats(unit.stats)
			
			# Update display if the method exists
			if unit.has_method("_update_attack_display"):
				unit._update_attack_display()
	
	# Gain +1 attack for each enemy affected
	if enemies_affected > 0:
		stats.attack += enemies_affected
		set_stats(stats)
		
		print("Drowned Shade: Tidal Haunting affected ", enemies_affected, " enemies, gained +", enemies_affected, " attack")
		
		# Play haunting sound effect
		if has_node("Buff"):
			$Buff.play()

func _ready() -> void:
	super._ready()

# Static function to reset Tidal Haunting effects after combat (like Tide Serpent)
static func reset_all_tidal_haunting(enemy_area: PlayArea):
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats.has_meta("drownedshade_original_attack"):
			var original_attack = unit.stats.get_meta("drownedshade_original_attack")
			unit.stats.attack = original_attack
			unit.stats.remove_meta("drownedshade_original_attack")
			unit.set_stats(unit.stats)