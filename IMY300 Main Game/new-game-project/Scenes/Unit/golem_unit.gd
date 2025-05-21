@tool
class_name GolemUnit
extends Unit

var buffed_units: Array = []

func update_aura(play_area: PlayArea) -> void:
	_remove_aura()
	
	# Find this Golem's tile
	var my_tile: Vector2i = Vector2i(-1, -1)
	for tile in play_area.unit_grid.units.keys():
		if play_area.unit_grid.units[tile] == self:
			my_tile = tile
			break
	if my_tile == Vector2i(-1, -1):
		return
	
	# Buff only adjacent units (not self, not already buffed)
	var offsets = [
		Vector2i(-1, 0), Vector2i(1, 0)
	]
	for offset in offsets:
		var adj_tile = my_tile + offset
		if play_area.unit_grid.units.has(adj_tile):
			var adj_unit = play_area.unit_grid.units[adj_tile]
			if adj_unit != null and adj_unit != self and not buffed_units.has(adj_unit):
				adj_unit.stats.attack += 2
				adj_unit.stats.health += 2
				adj_unit.set_stats(adj_unit.stats)
				buffed_units.append(adj_unit)

func _remove_aura() -> void:
	for unit in buffed_units:
		if unit:
			unit.stats.attack -= 2
			unit.stats.health -= 2
			unit.set_stats(unit.stats)
	buffed_units.clear()

func on_played(play_area: PlayArea) -> void:
	update_aura(play_area)

func on_removed_from_board(_play_area: PlayArea) -> void:
	_remove_aura()
