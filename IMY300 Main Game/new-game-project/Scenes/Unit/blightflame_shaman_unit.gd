@tool
class_name BlightflameShaman
extends Unit

# Toxic Touch: This unit kills any enemy unit it attacks or that attacks it (mutual destruction)
# Since it's a weak 1/1 unit, this makes it high-risk, high-reward

# This unit has a special property that will be checked in ForestBoard's _attack function
func _ready() -> void:
	super._ready()
	# Mark this unit as having the toxic touch ability
	if stats:
		stats.set_meta("has_toxic_touch", true)
	else:
		call_deferred("_check_stats_later")

func _check_stats_later():
	if stats:
		stats.set_meta("has_toxic_touch", true)

# Override take damage to implement the instant-kill mechanic
func take_combat_damage(_damage_amount: int, attacker_unit: Unit = null) -> void:
	# The Blightflame Shaman dies from any attack (since it has 1 health)
	stats.health = 0
	set_stats(stats)
	
	# But its toxic nature also kills the attacker instantly
	if attacker_unit and attacker_unit.stats:
		attacker_unit.stats.health = 0
		attacker_unit.set_stats(attacker_unit.stats)

# Override deal damage to implement the instant-kill mechanic  
func deal_combat_damage(target_unit: Unit) -> void:
	# The Blightflame Shaman kills any unit it attacks
	if target_unit and target_unit.stats:
		target_unit.stats.health = 0
		target_unit.set_stats(target_unit.stats)