extends Control

@onready var unit_mover: UnitMover = $UnitMover

func _ready() -> void:
	_update_ui()
	var states = GameState.load_state()
	var board_units = states["board_units"]
	var hand_units = states["hand_units"]
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

func _update_ui() -> void:
	# Hide all buttons initially
	$VBoxContainer/ShopButton.visible = false
	$VBoxContainer/CombineButton.visible = false
	$VBoxContainer/FightButton.visible = false

	# Show buttons based on the current step
	match GameState.current_step:
		GameState.GameStep.STEP_1, GameState.GameStep.STEP_2:
			$VBoxContainer/ShopButton.visible = true
			$VBoxContainer/CombineButton.visible = true
		GameState.GameStep.FIGHT:
			$VBoxContainer/ShopButton.visible = false
			$VBoxContainer/CombineButton.visible = false
			$VBoxContainer/FightButton.visible = true

func _on_ShopButton_pressed() -> void:
	# Load the Shop scene
	_load_scene("res://Scenes/Board/board.tscn")

func _on_CombineButton_pressed() -> void:
	# Load the Combine scene
	_load_scene("res://Scenes/combine_board/combineboard.tscn")

func _on_FightButton_pressed() -> void:
	# Load the Fight scene
	_load_scene("res://Scenes/forest_board/forestboard.tscn")

func _load_scene(scene_path: String) -> void:
	print("Changing scene to:", scene_path)
	GameState.update_step()  # Centralized game step update
	get_tree().change_scene_to_file(scene_path)
	_update_ui()
