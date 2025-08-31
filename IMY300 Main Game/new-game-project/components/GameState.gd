extends Node

# Define the game steps
enum GameStep { STEP_1, STEP_2, FIGHT , STEP_1_1, STEP_1_2, STEP_1_3, STEP_1_4, STEP_1_5, STEP_1_6, STEP_1_7, STEP_1_8, STEP_1_9, STEP_2_1}

# Track the current step
var current_step: GameStep = GameStep.STEP_1

# Store board and hand states
var board_units: Array = []
var hand_units: Array = []

var global_unit_pool: UnitPool
var last_generated_round: int = -1

@export var round_1_enemies: Array[EnemyStats] = []
@export var round_2_enemies: Array[EnemyStats] = []
@export var round_3_enemies: Array[EnemyStats] = []
@export var round_4_enemies: Array[EnemyStats] = []

func _ready():
	# Load the unit pool but don't generate it yet
	global_unit_pool = preload("res://data/unit_pool/unit_pool.tres")

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
	current_step = GameStep.STEP_1  # Start from STEP_1, not STEP_1_1
	main_round = 1
	main_step = MainStep.SHOP
	reset_state() # Clear any existing board/hand state
	print("Started tutorial mode, step: ", current_step)

func start_main_game() -> void:
	game_mode = GameMode.MAIN_GAME
	main_step = MainStep.SHOP
	main_round = 1
	main_complete = false
	reset_state() # keep your existing board/hand clear
	
	# Clear the unit pool to remove any leftover combined units from previous games
	if global_unit_pool:
		global_unit_pool.generate_unit_pool_for_round(main_round)
		last_generated_round = main_round
		print("Cleared unit pool for new main game - removed all combined units")

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
				return "res://scenes/board/board.tscn"
			MainStep.COMBINE:
				return "res://scenes/combine_board/combineboard.tscn"
			MainStep.FIGHT:
				return "res://scenes/forest_board/forestboard.tscn"
		return ""
	# Tutorial flow is driven by your UI in game_flow_manager, so stay there.
	return "res://scenes/game_flow_manager/GameFlowManager.tscn"

func is_main_complete() -> bool:
	return main_complete

func get_unit_pool() -> UnitPool:
	if not global_unit_pool:
		global_unit_pool = preload("res://data/unit_pool/unit_pool.tres")
		global_unit_pool.generate_unit_pool_for_round(main_round)
		last_generated_round = main_round
		print("Initial generation for round ", main_round)
	elif last_generated_round != main_round:
		# Only regenerate base pool, but preserve any added units
		var added_units = []
		# Save any combined units first
		for unit in global_unit_pool.unit_pool:
			if not unit.name in ["Rat", "Golem", "Flame Imp", "Moss Troll", "Spectre"]:  # Your base units
				added_units.append(unit)
		
		global_unit_pool.generate_unit_pool_for_round(main_round)
		
		# Add back the combined units
		for unit in added_units:
			global_unit_pool.add_unit(unit)
		
		last_generated_round = main_round
		print("Regenerated pool for round ", main_round, " with ", added_units.size(), " preserved units")
	
	return global_unit_pool

func get_enemies_for_round(round_num: int) -> EnemyStats:
	var enemy_pool: Array[EnemyStats] = []
	
	match round_num:
		1:
			enemy_pool = [
				preload("res://data/enemy/goblin.tres")
			]
		2:
			enemy_pool = [
				preload("res://data/enemy/goblin2.tres")
			]
		3:
			enemy_pool = [
				preload("res://data/enemy/goblin3.tres") 
			]
		4:
			enemy_pool = [
				preload("res://data/enemy/goblin_boss.tres") 
			]
		_:
			enemy_pool = [preload("res://data/enemy/goblin.tres")]
	
	if enemy_pool.size() == 0:
		print("No enemies configured for round ", round_num)
		return null
	
	# Pick a random enemy from the pool
	var selected_enemy = enemy_pool[randi() % enemy_pool.size()]
	print("Selected enemy: ", selected_enemy.resource_path)
	return selected_enemy
