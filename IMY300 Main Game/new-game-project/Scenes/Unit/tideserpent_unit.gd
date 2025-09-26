@tool
class_name TideSerpentUnit
extends Unit

# Crushing Depths: At the start of combat, set the strongest enemy's attack to 1
func on_combat_start(enemy_area: PlayArea, _player_area: PlayArea = null) -> void:
	# Find all living enemy units
	var enemies: Array = []
	for unit in enemy_area.unit_grid.units.values():
		if unit != null and unit.stats and unit.stats.health > 0:
			enemies.append(unit)
	
	if enemies.size() > 0:
		# Find the strongest enemy (highest attack)
		var strongest_enemy = enemies[0]
		for enemy in enemies:
			if enemy.stats.attack > strongest_enemy.stats.attack:
				strongest_enemy = enemy
		
		# Set the strongest enemy's attack to 1 (but only if it's higher than 1)
		if strongest_enemy.stats.attack > 1:
			_crush_enemy_attack(strongest_enemy)

func _crush_enemy_attack(target: Unit) -> void:
	if not target or not target.stats or target.stats.health <= 0:
		return
	
	# Store original attack value in metadata if not already stored
	if not target.stats.has_meta("tideserpent_original_attack"):
		target.stats.set_meta("tideserpent_original_attack", target.stats.attack)
	
	# Set attack to 1
	target.stats.attack = 1
	target.set_stats(target.stats)
