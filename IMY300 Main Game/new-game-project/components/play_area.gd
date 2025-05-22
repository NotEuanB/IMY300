class_name PlayArea
extends Node2D

@export var unit_grid: UnitGrid
@export var cell_size: Vector2 = Vector2(180, 305)  # Size of each grid cell
@export var area_type: String

var bounds: Rect2i

func _ready() -> void:
	bounds = Rect2i(Vector2i.ZERO, Vector2i(unit_grid.size.x * int(cell_size.x), unit_grid.size.y * int(cell_size.y)))

func get_tile_from_global(global: Vector2) -> Vector2i:
	var local_pos = to_local(global)
	var x = floor(local_pos.x / cell_size.x)
	var y = floor(local_pos.y / cell_size.y)
	return Vector2i(x, y)


func get_global_from_tile(tile: Vector2i) -> Vector2:
	return to_global(Vector2(tile.x, tile.y) * cell_size)


func get_hovered_tile() -> Vector2i:
	var local_mouse = get_local_mouse_position()
	return Vector2i(floor(local_mouse.x / cell_size.x), floor(local_mouse.y / cell_size.y))

func is_tile_in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < unit_grid.size.x and tile.y >= 0 and tile.y < unit_grid.size.y

func is_mouse_inside() -> bool:
	var local_mouse = get_local_mouse_position()
	return bounds.has_point(local_mouse)
