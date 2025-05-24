class_name CombinationBoard
extends Node2D

@onready var unit_mover: UnitMover = $UnitMover

func _ready() -> void:
	var states = GameState.load_state()
	var board_units = states[0]
	var hand_units = states[1]
	_spawn_units(board_units, $PlayArea)
	_spawn_units(hand_units, $HandArea)

func _spawn_units(units_data: Array, play_area: PlayArea) -> void:
	for unit_data in units_data:
		var stats = unit_data["stats"]
		var tile = unit_data["tile"]
		var unit_scene = stats.unit_scene if stats.unit_scene else preload("res://scenes/unit/unit.tscn")
		var unit = unit_scene.instantiate()
		play_area.unit_grid.add_child(unit)
		play_area.unit_grid.add_unit(tile, unit)
		unit.global_position = play_area.get_global_from_tile(tile)
		unit.stats = stats.duplicate()
		unit_mover.setup_unit(unit)
