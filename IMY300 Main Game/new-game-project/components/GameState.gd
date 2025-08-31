extends Node

# Define the game steps
enum GameStep { STEP_1, STEP_2, FIGHT , STEP_1_1, STEP_1_2, STEP_1_3, STEP_1_4, STEP_1_5, STEP_1_6, STEP_1_7, STEP_1_8, STEP_1_9, STEP_2_1}

# Track the current step
var current_step: GameStep = GameStep.STEP_1

# Store board and hand states
var board_units: Array = []
var hand_units: Array = []

func save_state(board_state: Array, hand_state: Array) -> void:
	board_units = board_state
	hand_units = hand_state
	print("Game state saved!")
	print("Board units:", board_units)
	print("Hand units:", hand_units)

func load_state() -> Dictionary:
	return { 
		"board_units": board_units,
		"hand_units": hand_units
	}

func update_step() -> void:
	match current_step:
		GameStep.STEP_1:
			current_step = GameStep.STEP_1_1
			print("Game step updated to STEP_1_1")
		GameStep.STEP_1_1:
			current_step = GameStep.STEP_1_2
			print("Game step updated to STEP_1_2")
		GameStep.STEP_1_2:
			current_step = GameStep.STEP_1_3
			print("Game step updated to STEP_1_3")
		GameStep.STEP_1_3:
			current_step = GameStep.STEP_1_4
			print("Game step updated to STEP_1_4")
		GameStep.STEP_1_4:
			current_step = GameStep.STEP_1_5
			print("Game step updated to STEP_1_5")
		GameStep.STEP_1_5:
			current_step = GameStep.STEP_1_6
			print("Game step updated to STEP_1_6")
		GameStep.STEP_1_6:
			current_step = GameStep.STEP_1_7
			print("Game step updated to STEP_1_7")
		GameStep.STEP_1_7:
			current_step = GameStep.STEP_1_8
			print("Game step updated to STEP_1_8")
		GameStep.STEP_1_8:
			current_step = GameStep.STEP_1_9
			print("Game step updated to STEP_1_9")
		GameStep.STEP_1_9:
			current_step = GameStep.STEP_2
			print("Game step updated to STEP_2")
		GameStep.STEP_2:
			current_step = GameStep.STEP_2_1
			print("Game step updated to STEP_2_1")
		GameStep.STEP_2_1:
			current_step = GameStep.FIGHT
			print("Game step updated to FIGHT")
		GameStep.FIGHT:
			print("Already in the fight step. No further steps.")

func reset_state() -> void:
	board_units = []
	hand_units = []

func reset_step() -> void:
	current_step = GameStep.STEP_1

# Add game modes (keep your existing tutorial enum/steps untouched)
enum GameMode { TUTORIAL, MAIN_GAME }
var game_mode: GameMode = GameMode.TUTORIAL

# Add a lightweight main-game loop (choice -> choice -> fight)
enum MainStep { SHOP, COMBINE, FIGHT }
var main_step: MainStep = MainStep.SHOP
var main_round: int = 1
const MAIN_MAX_ROUNDS: int = 4
var main_complete: bool = false

# Helper API (does not change your existing tutorial update_step)
func start_tutorial() -> void:
	game_mode = GameMode.TUTORIAL
	reset_step() # your existing function that sets current_step = STEP_1

func start_main_game() -> void:
	game_mode = GameMode.MAIN_GAME
	main_step = MainStep.SHOP
	main_round = 1
	main_complete = false
	reset_state() # keep your existing board/hand clear

func advance() -> void:
	if game_mode == GameMode.TUTORIAL:
		update_step() # use your existing tutorial progression
	else:
		_advance_main_step()

func _advance_main_step() -> void:
	match main_step:
		MainStep.SHOP:
			main_step = MainStep.COMBINE
		MainStep.COMBINE:
			main_step = MainStep.FIGHT
		MainStep.FIGHT:
			if main_round < MAIN_MAX_ROUNDS:
				main_round += 1
				main_step = MainStep.SHOP
			else:
				main_complete = true

func get_next_scene_path() -> String:
	if game_mode == GameMode.MAIN_GAME:
		match main_step:
			MainStep.SHOP:
				return "res://Scenes/Board/board.tscn"
			MainStep.COMBINE:
				return "res://Scenes/combine_board/combineboard.tscn"
			MainStep.FIGHT:
				return "res://Scenes/forest_board/forestboard.tscn"
		return ""
	# Tutorial flow is driven by your UI in game_flow_manager, so stay there.
	return "res://Scenes/game_flow_manager/game_flow_manager.tscn"

func is_main_complete() -> bool:
	return main_complete
