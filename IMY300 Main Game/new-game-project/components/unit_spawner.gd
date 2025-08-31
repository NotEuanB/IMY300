class_name UnitSpawner
extends Node

signal unit_spawned(unit: Unit)

const UNIT = preload("res://scenes/unit/unit.tscn")

@export var hand_area: PlayArea


signal hand_full_changed(is_full: bool)

func _ready() -> void:
	hand_area.unit_grid.unit_grid_changed.connect(_on_hand_grid_changed)
	_on_hand_grid_changed() # Initial check

func _on_hand_grid_changed() -> void:
	var full = hand_area.unit_grid.is_grid_full()
	hand_full_changed.emit(full)

func _get_first_available_area() -> PlayArea:
	if not hand_area.unit_grid.is_grid_full():
		return hand_area
	
	return null

func spawn_unit(unit: UnitStats) -> Unit:
	var area := _get_first_available_area()
	if area == null:
		print("⚠ No available space to add unit to hand!")
		return null
	
	var unit_scene := unit.unit_scene if unit.unit_scene else UNIT
	var new_unit := unit_scene.instantiate()
	var tile := area.unit_grid.get_first_empty_tile()
	new_unit.add_to_group("units")
	area.unit_grid.add_child(new_unit)
	area.unit_grid.add_unit(tile, new_unit)
	new_unit.global_position = area.get_global_from_tile(tile)
	
	# Ensure base stats are initialized before duplicating
	unit.initialize_base_stats()
	
	# Duplicate the stats (this will now include the base stats)
	var duplicated_stats = unit.duplicate()
	
	new_unit.stats = duplicated_stats
	unit_spawned.emit(new_unit)
	return new_unit
