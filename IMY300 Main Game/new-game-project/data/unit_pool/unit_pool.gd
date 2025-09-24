class_name UnitPool
extends Resource

@export var available_units: Array[UnitStats]

var unit_pool: Array[UnitStats]

func generate_unit_pool() -> void:
	unit_pool.clear()
	
	# Use pool_count instead of amount_in_pool
	for unit in available_units:
		for i in range(unit.pool_count):
			unit_pool.append(unit)
	

func generate_unit_pool_for_round(round: int) -> void:
	unit_pool.clear()
	
	for unit in available_units:
		var spawn_count = get_spawn_count_for_round(unit, round)
		for i in range(spawn_count):
			unit_pool.append(unit)
	
func get_spawn_count_for_round(unit: UnitStats, round: int) -> int:
	var tier = unit.tier
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

func get_random_unit_without_removing() -> UnitStats:
	if unit_pool.is_empty():
		return null
	
	var random_index = randi() % unit_pool.size()
	return unit_pool[random_index]

func add_unit(unit: UnitStats) -> void:
	unit_pool.append(unit)

func remove_unit_from_pool(unit_stats: UnitStats) -> void:
	var index = unit_pool.find(unit_stats)
	if index != -1:
		unit_pool.remove_at(index)
