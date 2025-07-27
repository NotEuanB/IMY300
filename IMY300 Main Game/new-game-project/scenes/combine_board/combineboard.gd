class_name CombinationBoard
extends Node2D

@onready var unit_mover: UnitMover = $UnitMover
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var tutorial_popup = $TutorialPopup
@onready var tutorial_text = $TutorialPopup/TutorialText

var paused = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pauseMenu()

func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	
	paused = !paused


func _show_tutorial_popup() -> void:
	match GameState.current_step:
		GameState.GameStep.STEP_2_1: 
			tutorial_text.text = "This is the combine screen, where you can combine units to make a new one.\nBy looking at your units, you can see a yellow uncracked gem in the middle, which means it can be combined with another unit. Units cannot be combined with themself.\nDrag 2 different units into the slots and press the combine button to see the magic happen!"
			tutorial_popup.position.x = 300
			tutorial_popup.position.y = 400

func _ready() -> void:
	var states = GameState.load_state()
	var board_units = states["board_units"]
	var hand_units = states["hand_units"]
	_spawn_units(board_units, $PlayArea)
	_spawn_units(hand_units, $HandArea)
	_show_tutorial_popup()

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
