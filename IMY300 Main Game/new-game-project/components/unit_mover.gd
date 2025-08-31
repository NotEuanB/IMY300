class_name UnitMover
extends Node

static var is_selecting_target: bool = false
static var selecting_rat: RatUnit = null
@export var play_area_paths: Array[NodePath]

var play_areas: Array[PlayArea] = []

var enabled: bool = true

func set_enabled(value: bool) -> void:
	enabled = value

func _ready() -> void:
	play_areas.clear()
	for path in play_area_paths:
		var node = get_node_or_null(path)
		if node and node is PlayArea:
			play_areas.append(node)
		else:
			push_error("Node at %s is not a PlayArea!" % path)
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		setup_unit(unit)



func setup_unit(unit: Unit) -> void:
	unit.drag_and_drop.drag_started.connect(_on_unit_drag_started.bind(unit))
	unit.drag_and_drop.drag_canceled.connect(_on_unit_drag_canceled.bind(unit))
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))



func _get_play_area_for_position(global: Vector2) -> int:
	for i in range(play_areas.size()):
		var tile := play_areas[i].get_tile_from_global(global)
		if play_areas[i].is_tile_in_bounds(tile):
			return i
	return -1


func _reset_unit_to_starting_position(starting_position: Vector2, unit: Unit) -> void:
	var i := _get_play_area_for_position(starting_position)
	if i == -1:
		return
	var tile := play_areas[i].get_tile_from_global(starting_position)
	if not play_areas[i].is_tile_in_bounds(tile):
		return
	unit.reset_after_dragging(starting_position)
	play_areas[i].unit_grid.add_unit(tile, unit)


func _move_unit(unit: Unit, play_area: PlayArea, tile: Vector2i) -> void:
	if not play_area.is_tile_in_bounds(tile):
		return
	unit.global_position = play_area.get_global_from_tile(tile)
	unit.reparent(play_area.unit_grid)
	play_area.unit_grid.add_unit(tile, unit)
	# Subtle shake on successful placement on the board
	if play_area.area_type == "board":
		var cams := get_tree().get_nodes_in_group("camera_shake")
		if cams.size() > 0:
			var cam = cams[0]
			if cam and cam.has_method("shake"):
				cam.shake(3.0, 0.08, 5)


func _on_unit_drag_started(unit: Unit) -> void:
	if not enabled:
		return
	for i in play_areas.size():
		if unit.get_parent() == play_areas[i].unit_grid:
			# Find the tile in this grid that contains the unit
			for tile in play_areas[i].unit_grid.units.keys():
				if play_areas[i].unit_grid.units[tile] == unit:
					play_areas[i].unit_grid.remove_unit(tile)
					unit.set_meta("last_grid_index", i)
					unit.set_meta("last_tile", tile)
					if unit is GolemUnit:
						unit.on_removed_from_board(play_areas[i])
					return


func _on_unit_drag_canceled(starting_position: Vector2, unit: Unit) -> void:
	if not enabled:
		return
	_reset_unit_to_starting_position(starting_position, unit)


func _on_unit_dropped(starting_position: Vector2, unit: Unit) -> void:
	if not enabled:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var old_area_index := int(unit.get_meta("last_grid_index", -1))
	var old_tile_variant = unit.get_meta("last_tile", null)
	var old_tile: Vector2i = old_tile_variant if typeof(old_tile_variant) == TYPE_VECTOR2I else Vector2i(-1, -1)
	var drop_area_index := _get_play_area_for_position(mouse_pos)	
	
	if drop_area_index == -1 or old_area_index == -1 or old_tile == Vector2i(-1, -1):
		_reset_unit_to_starting_position(starting_position, unit)
		return	
	var old_area := play_areas[old_area_index]
	var new_area := play_areas[drop_area_index]
	var new_tile := new_area.get_tile_from_global(mouse_pos)
	if not new_area.is_tile_in_bounds(new_tile):
		_reset_unit_to_starting_position(starting_position, unit)
		return		
	
	# Prevent swapping between hand and board
	var hand_area_index = 0
	var is_drag_from_hand = (old_area_index == hand_area_index)
	var is_drop_to_hand = (drop_area_index == hand_area_index)

	# Prevent dropping units into hand unless they came from hand
	if is_drop_to_hand and not is_drag_from_hand:
		_reset_unit_to_starting_position(starting_position, unit)
		return

	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_unit: Unit = new_area.unit_grid.units[new_tile]
		var is_target_in_hand = (new_area == play_areas[hand_area_index])
		# Block swap if either dragged unit or target unit is in hand
		if is_drag_from_hand or is_target_in_hand:
			_reset_unit_to_starting_position(starting_position, unit)
			return
		# Otherwise, allow swap on board
		new_area.unit_grid.remove_unit(new_tile)
		_move_unit(old_unit, old_area, old_tile)
	_move_unit(unit, new_area, new_tile)

	if new_area.area_type == "board":
		unit.on_played(new_area)
	
	if new_area == play_areas[1]:
		for u in play_areas[1].unit_grid.units.values():
			if is_instance_valid(u) and u is GolemUnit:
				u.update_aura(play_areas[1])
	$Place.play()
