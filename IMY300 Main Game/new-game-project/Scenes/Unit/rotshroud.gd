@tool
class_name RotshroudUnit
extends Unit

# Decay Aura: At start of combat, all enemy units lose -1 health
func on_combat_start(enemy_area: PlayArea, _player_area: PlayArea = null) -> void:	
	var enemies_affected = 0
	
	# Find all enemy units and reduce their health by 1
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			# Check for Coral Colossus immunity before applying damage
			var damage = _apply_coral_aegis_immunity(unit, 1)
			
			# Reduce enemy health by damage amount
			unit.stats.health -= damage
			
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
