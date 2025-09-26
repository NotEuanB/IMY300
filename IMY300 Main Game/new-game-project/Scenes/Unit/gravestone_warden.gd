@tool
class_name GravestoneWardenUnit
extends Unit

# Guardian's Vigil: Adjacent allies take 1 less damage from all sources (minimum 1)
func on_played(play_area: PlayArea) -> void:
	print("Gravestone Warden: Guardian's Vigil activated")
	_update_vigil_aura(play_area)

func _update_vigil_aura(play_area: PlayArea) -> void:
	# Find this Warden's tile
	var my_tile: Vector2i = Vector2i(-1, -1)
	for tile in play_area.unit_grid.units.keys():
		if play_area.unit_grid.units[tile] == self:
			my_tile = tile
			break
	
	if my_tile == Vector2i(-1, -1):
		return
	
	# Mark adjacent units as protected by this warden
	var offsets = [Vector2i(-1, 0), Vector2i(1, 0)]
	for offset in offsets:
		var adj_tile = my_tile + offset
		if play_area.unit_grid.units.has(adj_tile):
			var adj_unit = play_area.unit_grid.units[adj_tile]
			if adj_unit != null and adj_unit != self:
				# Add damage reduction metadata
				if not adj_unit.has_meta("damage_reduction"):
					adj_unit.set_meta("damage_reduction", 0)
				adj_unit.set_meta("damage_reduction", adj_unit.get_meta("damage_reduction") + 1)
				
				# Track which warden is protecting this unit
				if not adj_unit.has_meta("protected_by_wardens"):
					adj_unit.set_meta("protected_by_wardens", [])
				adj_unit.get_meta("protected_by_wardens").append(self)
				
				print("Gravestone Warden: Protecting adjacent unit with damage reduction")

func on_removed_from_board(play_area: PlayArea) -> void:
	_remove_vigil_aura(play_area)

func _remove_vigil_aura(play_area: PlayArea) -> void:
	# Remove damage reduction from all units protected by this warden
	for tile in play_area.unit_grid.units.keys():
		var unit = play_area.unit_grid.units[tile]
		if unit != null and unit.has_meta("protected_by_wardens"):
			var wardens = unit.get_meta("protected_by_wardens")
			if self in wardens:
				wardens.erase(self)
				# Reduce damage reduction by 1
				var current_reduction = unit.get_meta("damage_reduction", 0)
				unit.set_meta("damage_reduction", max(0, current_reduction - 1))
				
				if wardens.size() == 0:
					unit.remove_meta("protected_by_wardens")
				if unit.get_meta("damage_reduction", 0) <= 0:
					unit.remove_meta("damage_reduction")

func _ready() -> void:
	super._ready()
