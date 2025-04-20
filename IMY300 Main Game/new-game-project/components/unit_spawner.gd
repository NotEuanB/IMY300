class_name UnitSpawner
extends Node

signal unit_spawned(unit: Unit)

const UNIT = preload("res://scenes/unit/unit.tscn")

@export var shop: PlayArea
@export var game_area: PlayArea
@export var hand_area: PlayArea


func _get_first_available_area() -> PlayArea:
	if not hand_area.unit_grid.is_grid_full():
		return hand_area
	elif not game_area.unit_grid.is_grid_full():
		return game_area
	
	return null


func spawn_unit(unit: UnitStats) -> void:
	var area := _get_first_available_area()
	# TODO in the future, throw a popup error message here!
	assert(area, "No available space to add unit to!")
	
	var new_unit := UNIT.instantiate()
	var tile := area.unit_grid.get_first_empty_tile()
	area.unit_grid.add_child(new_unit)
	area.unit_grid.add_unit(tile, new_unit)
	new_unit.global_position = area.get_global_from_tile(tile) - Shop.HALF_CELL_SIZE
	new_unit.stats = unit
	unit_spawned.emit(new_unit)
