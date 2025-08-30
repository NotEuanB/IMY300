class_name UnitPool
extends Resource

@export var available_units: Array[UnitStats]

var unit_pool: Array[UnitStats]

func generate_unit_pool() -> void:
	unit_pool = []
	var current_round = GameState.main_round if GameState.game_mode == GameState.GameMode.MAIN_GAME else 1
	
	for unit: UnitStats in available_units:
		var spawn_count = get_spawn_count_for_round(unit, current_round)
		for i in spawn_count:
			unit_pool.append(unit)

func get_spawn_count_for_round(unit: UnitStats, round: int) -> int:
	var tier = unit.tier  # Now use the unit's tier property directly
	var base_count = unit.pool_count
	
	match tier:
		1: # Tier 1 - always full availability
			return base_count
		2: # Tier 2 - gradual introduction
			match round:
				1:
					return 0
				2:
					return max(1, base_count / 2)  # 50% availability
				_:
					return base_count  # Full availability from round 3+
		3: # Tier 3 - late game
			match round:
				1, 2:
					return 0
				3:
					return max(1, base_count / 3)  # 33% availability
				_:
					return base_count  # Full availability from round 4+
		_:
			return base_count

func get_random_unit() -> UnitStats:
	var units := unit_pool
	
	if units.is_empty():
		return null
	
	var picked_unit: UnitStats = units.pick_random()
	unit_pool.erase(picked_unit)
	
	return picked_unit

func add_unit(unit: UnitStats) -> void:
	unit_pool.append(unit)
