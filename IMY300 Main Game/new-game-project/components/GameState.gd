extends Node

# Define the game steps
enum GameStep { STEP_1, STEP_2, FIGHT }

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
			current_step = GameStep.STEP_2
			print("Game step updated to STEP_2")
		GameStep.STEP_2:
			current_step = GameStep.FIGHT
			print("Game step updated to FIGHT")
		GameStep.FIGHT:
			print("Already in the fight step. No further steps.")
