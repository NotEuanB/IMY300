extends Node2D

@onready var unit_mover: UnitMover = $UnitMover
@onready var unit_spawner: UnitSpawner = $UnitSpawner
@onready var board_area: PlayArea = $PlayArea
@onready var hand_area: PlayArea = $HandArea
@onready var pause_menu = $PauseLayer/PauseMenu
var paused = false

func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	
	paused = !paused

func _ready() -> void:
	$FlowMenuAnimation/FlowMenuAnimation.play("Flowmenu_idle")
	_update_ui()
	var states = GameState.load_state()
	var board_units = states["board_units"]
	var hand_units = states["hand_units"]
	_spawn_units(board_units, board_area)
	_spawn_units(hand_units, hand_area)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pauseMenu()

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
	$ShopButton.visible = false
	$CombineButton.visible = false
	$FightButton.visible = false

	# Show buttons based on the current step
	match GameState.current_step:
		GameState.GameStep.STEP_1, GameState.GameStep.STEP_2:
			$ShopButton.visible = true
			$CombineButton.visible = true
		GameState.GameStep.FIGHT:
			$ShopButton.visible = false
			$CombineButton.visible = false
			$FightButton.visible = true

func _load_scene(scene_path: String) -> void:
	print("Changing scene to:", scene_path)
	GameState.update_step()  # Centralized game step update
	get_tree().change_scene_to_file(scene_path)
	_update_ui()

func get_hand_state() -> Array:
	var hand = []
	for tile in unit_spawner.hand_area.unit_grid.units:
		var unit = unit_spawner.hand_area.unit_grid.units[tile]
		if unit:
			hand.append({
				"stats": unit.stats,
				"tile": tile
			})
	return hand

func get_board_state() -> Array:
	# If you have a board area, replace 'board_area' with the correct variable
	var board = []
	for tile in board_area.unit_grid.units:
		var unit = board_area.unit_grid.units[tile]
		if unit:
			board.append({
				"stats": unit.stats,
				"tile": tile
			})
	return board


func _on_fight_button_pressed() -> void:
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	GameState.save_state(board_state, hand_state)
	# Load the Fight scene
	_load_scene("res://Scenes/forest_board/forestboard.tscn")


func _on_combine_button_pressed() -> void:
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	GameState.save_state(board_state, hand_state)
	# Load the Combine scene
	_load_scene("res://Scenes/combine_board/combineboard.tscn")


func _on_shop_button_pressed() -> void:
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	GameState.save_state(board_state, hand_state)
	# Load the Shop scene
	_load_scene("res://Scenes/Board/board.tscn")
