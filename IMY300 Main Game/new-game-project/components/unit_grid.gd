class_name UnitGrid
extends Node2D

signal unit_grid_changed

@export var size: Vector2i

var units: Dictionary


func _ready() -> void:
	for i in size.x:
		for j in size.y:
			units[Vector2i(i, j)] = null
	queue_redraw()

func add_unit(tile: Vector2i, unit: Node) -> void:
	if not units.has(tile):
		return
	units[tile] = unit
	unit_grid_changed.emit()

func _draw():
	var cell_size = Vector2(180, 305) # Change to your actual cell size if different
	for i in size.x:
		for j in size.y:
			var pos = Vector2(i, j) * cell_size
			draw_rect(Rect2(pos, cell_size), Color(1, 1, 0, 1), false, 10.0) # Yellow outline, 2px thick

func remove_unit(tile: Vector2i) -> void:
	if not units.has(tile):
		print("Tried to remove from invalid tile: ", tile)
		return
	var unit := units[tile] as Node
	if not unit:
		print("No unit at tile: ", tile)
		return
	units[tile] = null
	unit_grid_changed.emit()

func is_tile_occupied(tile: Vector2i) -> bool:
	if not units.has(tile):
		return false
	return units[tile] != null


func is_grid_full() -> bool:
	return units.keys().all(is_tile_occupied)


func get_first_empty_tile() -> Vector2i:
	for tile in units:
		if not is_tile_occupied(tile):
			return tile
	
	# no empty tile
	return Vector2i(-1, -1)


func get_all_units() -> Array[Unit]:
	var unit_array: Array[Unit] = []
	
	for unit: Unit in units.values():
		if unit:
			unit_array.append(unit)
	
	return unit_array
