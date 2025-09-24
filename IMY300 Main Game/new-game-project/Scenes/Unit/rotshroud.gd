@tool
class_name RotshroudUnit
extends Unit

# Decay Aura: At start of combat, all enemy units lose -1 health
func on_combat_start(enemy_area: PlayArea, _player_area: PlayArea = null) -> void:	
	var enemies_affected = 0
	
	# Find all enemy units and reduce their health by 1
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			# Reduce enemy health by 1
			unit.stats.health -= 1
			
			# Make sure health doesn't go below 1 (minimum)
			if unit.stats.health < 1:
				unit.stats.health = 1
			
			unit.set_stats(unit.stats)
			enemies_affected += 1
	
	if enemies_affected > 0:		
		# Play decay sound effect (with null check)
		if has_node("Buff"):
			$Buff.play()

func _ready() -> void:
	super._ready()
