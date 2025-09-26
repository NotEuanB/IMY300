@tool
class_name MossTrollUnit
extends Unit

# Nature's Resilience: Start of combat - Gain +1 health for each other friendly unit
func on_combat_start(_enemy_area: PlayArea, _player_area: PlayArea = null) -> void:
	# Count other friendly units (excluding self)
	var friendly_count = 0
		
	if _player_area:		
		# Try to find unit_grid as a property
		if "unit_grid" in _player_area:
			var unit_grid = _player_area.unit_grid
			if unit_grid:				
				for unit in unit_grid.units.values():
					if unit != null:
						if unit != self and unit.stats and unit.stats.health > 0:
							friendly_count += 1
		elif _player_area.has_node("UnitGrid"):
			var unit_grid = _player_area.get_node("UnitGrid")
			if unit_grid and "units" in unit_grid:
				for unit in unit_grid.units.values():
					if unit != null:
						if unit != self and unit.stats and unit.stats.health > 0:
							friendly_count += 1
	
	if friendly_count > 0:
		# Gain +1 health for each other friendly unit
		var health_bonus = friendly_count
		var old_health = stats.health
		stats.health += health_bonus
		
		# Also update base_health so it's permanent
		stats.base_health += health_bonus
		
		# Update max health tracking to ensure it shows up correctly
		if stats.health > max_health_reached:
			max_health_reached = stats.health
		
		# Force update display
		set_stats(stats)
		
		# Play buff sound effect
		if has_node("Buff"):
			$Buff.play()

func _ready() -> void:
	super._ready()
