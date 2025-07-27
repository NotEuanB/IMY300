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
