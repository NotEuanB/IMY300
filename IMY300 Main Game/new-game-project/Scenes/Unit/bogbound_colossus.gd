@tool
class_name BogboundColossusUnit
extends Unit

# Swamp Fortification: On played, gain +2 health for each adjacent ally. 
# Then give all allies +1/+1 permanently.
func on_played(player_area: PlayArea) -> void:
	print("Bogbound Colossus: on_played called")
	
	if not player_area:
		print("Bogbound Colossus: No player area provided")
		return
	
	# Phase 1: Count adjacent allies and gain health
	var adjacent_allies = _count_adjacent_allies(player_area)
	if adjacent_allies > 0:
		var health_bonus = adjacent_allies * 2
		stats.health += health_bonus
		stats.base_health += health_bonus  # Make it permanent
		
		print("Bogbound Colossus: Found ", adjacent_allies, " adjacent allies, gained ", health_bonus, " health")
		set_stats(stats)
	
	# Phase 2: Give all allies +1/+1 permanently
	var allies_buffed = 0
	if player_area and "unit_grid" in player_area:
		var unit_grid = player_area.unit_grid
		if unit_grid and "units" in unit_grid:
			for unit in unit_grid.units.values():
				if unit != null and unit != self and unit.stats and unit.stats.health > 0:
					# Give permanent +1/+1 buff
					unit.stats.attack += 1
					unit.stats.health += 1
					unit.stats.base_attack += 1  # Make it permanent
					unit.stats.base_health += 1  # Make it permanent
					unit.set_stats(unit.stats)
					allies_buffed += 1
	
	if allies_buffed > 0:
		print("Bogbound Colossus: Buffed ", allies_buffed, " allies with +1/+1")
		
		# Play buff sound effect
		if has_node("Buff"):
			$Buff.play()

func _count_adjacent_allies(player_area: PlayArea) -> int:
	# Find this Colossus's position
	var my_tile: Vector2i = Vector2i(-1, -1)
	if player_area and "unit_grid" in player_area:
		var unit_grid = player_area.unit_grid
		if unit_grid and "units" in unit_grid:
			for tile in unit_grid.units.keys():
				if unit_grid.units[tile] == self:
					my_tile = tile
					break
	
	if my_tile == Vector2i(-1, -1):
		return 0
	
	# Count adjacent allies (left and right)
	var adjacent_count = 0
	var offsets = [Vector2i(-1, 0), Vector2i(1, 0)]
	
	if player_area and "unit_grid" in player_area:
		var unit_grid = player_area.unit_grid
		if unit_grid and "units" in unit_grid:
			for offset in offsets:
				var adj_tile = my_tile + offset
				if unit_grid.units.has(adj_tile):
					var adj_unit = unit_grid.units[adj_tile]
					if adj_unit != null and adj_unit != self and adj_unit.stats and adj_unit.stats.health > 0:
						adjacent_count += 1
	
	return adjacent_count

func _ready() -> void:
	super._ready()
