@tool
class_name ShadebladeUnit
extends Unit

# Shadow Resurrection: Automatically buffs a random ally +1/+1, first ally death each combat gets revived with 1 HP
func on_played(play_area: PlayArea) -> void:
	if stats.buff_used:
		return

	var candidates: Array = []
	for unit in play_area.unit_grid.units.values():
		if unit != null and unit != self:
			candidates.append(unit)
	
	if candidates.size() == 0:
		return

	# Pick a random ally to buff (automatic, no targeting)
	var target = candidates[randi() % candidates.size()]
	
	# Give the target +1/+1 (same as Rat)
	target.stats.attack += 1
	target.stats.health += 1
	target.set_stats(target.stats)
	
	stats.buff_used = true
	
	# Play buff sound effect (with null check)
	if has_node("Buff"):
		$Buff.play()


# Note: The resurrection logic will be implemented in the ForestBoard
# We'll store a flag to indicate this unit provides resurrection
func _ready() -> void:
	super._ready()
	# Mark that this unit provides shadow resurrection (but DON'T reset buff_used)
	if stats:
		stats.set_meta("provides_shadow_resurrection", true)
	else:
		call_deferred("_check_stats_later")

func _check_stats_later():
	if stats:
		stats.set_meta("provides_shadow_resurrection", true)
