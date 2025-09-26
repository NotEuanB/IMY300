@tool
class_name SpectreUnit
extends Unit

# Soul Drain: When this unit kills an enemy, gain +1/+1 permanently
func on_kill(_killed_unit: Unit) -> void:

	
	# Just increase current stats like the Rat does
	# But also track how many souls we've drained
	stats.attack += 1
	stats.health += 1
	
	# Update max_health_reached to include the new health bonus
	if stats.health > max_health_reached:
		max_health_reached = stats.health
	
	# Store the soul count in a custom property to persist through save/load
	if not stats.has_meta("souls_drained"):
		stats.set_meta("souls_drained", 0)
	var souls = stats.get_meta("souls_drained") + 1
	stats.set_meta("souls_drained", souls)
	

	
	# Mark the resource as changed to ensure it saves properly
	stats.changed.emit()
	
	# Don't call set_stats() to avoid potential conflicts
	# Just update the display directly
	if unit_atk and unit_hp:
		update_stat_display_attack(unit_atk, stats.attack, base_attack)
		update_stat_display_health(unit_hp, stats.health, base_health, stats.health)
	


func _ready() -> void:
	super._ready()
	if stats:
		# Restore soul drain bonuses when spawned
		if stats.has_meta("souls_drained"):
			var _souls = stats.get_meta("souls_drained")
			# The stats should already have the bonuses from previous soul drains
