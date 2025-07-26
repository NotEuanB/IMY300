extends Node2D

@onready var unit_mover: UnitMover = $UnitMover
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


func _on_fight_button_pressed() -> void:
	# Load the Fight scene
	_load_scene("res://Scenes/forest_board/forestboard.tscn")


func _on_combine_button_pressed() -> void:
	# Load the Combine scene
	_load_scene("res://Scenes/combine_board/combineboard.tscn")


func _on_shop_button_pressed() -> void:
	# Load the Shop scene
	_load_scene("res://Scenes/Board/board.tscn")
