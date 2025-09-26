@tool
class_name RootsnareBanditUnit
extends Unit

# Growing Snare: When played, all other allied units gain +1 health permanently
func on_played(play_area: PlayArea) -> void:
	if stats.buff_used:
		return

	var allies_buffed = 0
	
	# Find all other allied units and buff their health
	for unit in play_area.unit_grid.units.values():
		if unit != null and unit != self and unit.stats:
			# Give +1 health permanently
			unit.stats.health += 1
			unit.stats.base_health += 1
			unit.set_stats(unit.stats)
			allies_buffed += 1
	
	if allies_buffed > 0:
		stats.buff_used = true
		
		# Play buff sound effect
		if has_node("Buff"):
			$Buff.play()

func _ready() -> void:
	super._ready()
