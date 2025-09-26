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

# Family system
var family_system: FamilySystem
var global_family_display: Label = null

@export var round_1_enemies: Array[EnemyStats] = []
@export var round_2_enemies: Array[EnemyStats] = []
@export var round_3_enemies: Array[EnemyStats] = []
@export var round_4_enemies: Array[EnemyStats] = []

func _ready():
	# Load the unit pool but don't generate it yet
	global_unit_pool = preload("res://data/unit_pool/unit_pool.tres")
	
	# Initialize family system
	family_system = FamilySystem.new()
	add_child(family_system)
	
	# Create global family display
	_create_global_family_display()

func save_state(board_state: Array, hand_state: Array) -> void:
	board_units = board_state
	hand_units = hand_state

func load_state() -> Dictionary:
	return { 
		"board_units": board_units,
		"hand_units": hand_units
	}

func update_step() -> void:
	match current_step:
		GameStep.STEP_1:
			current_step = GameStep.STEP_1_1
		GameStep.STEP_1_1:
			current_step = GameStep.STEP_1_2
		GameStep.STEP_1_2:
			current_step = GameStep.STEP_1_3
		GameStep.STEP_1_3:
			current_step = GameStep.STEP_1_4
		GameStep.STEP_1_4:
			current_step = GameStep.STEP_1_5
		GameStep.STEP_1_5:
			current_step = GameStep.STEP_1_6
		GameStep.STEP_1_6:
			current_step = GameStep.STEP_1_7
		GameStep.STEP_1_7:
			current_step = GameStep.STEP_1_8
		GameStep.STEP_1_8:
			current_step = GameStep.STEP_1_9
		GameStep.STEP_1_9:
			current_step = GameStep.STEP_2
		GameStep.STEP_2:
			current_step = GameStep.STEP_2_1
		GameStep.STEP_2_1:
			current_step = GameStep.FIGHT

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
const MAIN_MAX_ROUNDS: int = 12
var main_complete: bool = false

# Helper API (does not change your existing tutorial update_step)
func start_tutorial() -> void:
	game_mode = GameMode.TUTORIAL
	current_step = GameStep.STEP_1_1  # Start directly at the first board tutorial step

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
	
	return global_unit_pool

func get_enemies_for_round(current_round: int) -> EnemyStats:
	var enemy_pool: Array[EnemyStats] = []
	
	match current_round:
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
		5, 6:
			enemy_pool = [
				preload("res://data/enemy/goblin.tres")
			]
		7, 8:
			enemy_pool = [
				preload("res://data/enemy/goblin2.tres") 
			]
		9, 10, 11:
			enemy_pool = [
				preload("res://data/enemy/goblin3.tres") 
			]
		12:
			enemy_pool = [
				preload("res://data/enemy/goblin_boss.tres") 
			]
		_:
			enemy_pool = [preload("res://data/enemy/goblin.tres")]
	
	if enemy_pool.size() == 0:
		return null
	
	# Pick a random enemy from the pool
	var selected_enemy = enemy_pool[randi() % enemy_pool.size()]
	return selected_enemy

# Family system functions
func apply_family_bonuses_to_board(units_on_board: Array) -> void:
	if family_system:
		family_system.update_family_auras(units_on_board)

func get_active_family_bonuses() -> Dictionary:
	if family_system:
		return family_system.get_active_bonuses()
	return {}

func get_family_counts() -> Dictionary:
	if family_system:
		return family_system.family_counts
	return {}

func _create_global_family_display():
	"""Create a global family display that persists across scenes"""
	# Create a CanvasLayer to ensure it persists across scene changes
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "GlobalFamilyDisplayLayer"
	canvas_layer.layer = 100  # High layer to stay on top
	
	global_family_display = Label.new()
	global_family_display.name = "GlobalFamilyDisplay"
	global_family_display.position = Vector2(20, 50)
	global_family_display.size = Vector2(400, 300)
	global_family_display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	global_family_display.add_theme_font_size_override("font_size", 12)
	global_family_display.add_theme_color_override("font_color", Color.WHITE)
	global_family_display.add_theme_color_override("font_shadow_color", Color.BLACK)
	global_family_display.add_theme_constant_override("shadow_offset_x", 2)
	global_family_display.add_theme_constant_override("shadow_offset_y", 2)
	global_family_display.visible = true  # Always visible for testing
	global_family_display.text = "FAMILY SYSTEM ACTIVE"  # Test text
	
	# Add label to canvas layer
	canvas_layer.add_child(global_family_display)
	
	# Add canvas layer to the scene tree (this will persist across scene changes)
	add_child(canvas_layer)
	print("Family Display: Created with persistent CanvasLayer")

func refresh_global_family_display():
	"""Update the global family display with current bonuses"""
	print("Family Display: Refresh called")
	
	if not global_family_display or not is_instance_valid(global_family_display):
		print("Family Display: Display not valid, recreating...")
		_create_global_family_display()
		return
		
	var active_bonuses = get_active_family_bonuses()
	var family_counts = get_family_counts()
	
	print("Family Display: Active bonuses: ", active_bonuses)
	print("Family Display: Family counts: ", family_counts)
	
	if active_bonuses.size() > 0:
		global_family_display.visible = true
		var text_lines = ["=== FAMILY BONUSES ==="]
		
		var family_names = ["Rats", "Golems", "Imps", "Trolls", "Spectres", "Leviathans"]
		
		for family_type in active_bonuses:
			var family_data = active_bonuses[family_type]
			var count = family_data.count
			var bonuses = family_data.bonuses
			
			text_lines.append("")
			text_lines.append("%s (%d units):" % [family_names[family_type], count])
			
			# Process each bonus description from the bonuses array
			for bonus_text in bonuses:
				text_lines.append("  • %s" % bonus_text)
		
		var final_text = "\n".join(text_lines)
		global_family_display.text = final_text
		print("Family Display: Updated text: ", final_text)
	else:
		global_family_display.text = "FAMILY SYSTEM: No active bonuses"
		global_family_display.visible = true  # Keep visible for debugging
		print("Family Display: No active bonuses")

func _get_bonus_description(bonus_name: String, _family_type: int, count: int) -> String:
	match bonus_name:
		"pack_hunter":
			var damage_bonus = (count - 1) * 2
			return "Pack Hunter: +%d damage per attack" % damage_bonus
		"swarm_tactics":
			return "Swarm Tactics: +%d health" % count
		"coordinated_assault":
			return "Coordinated Assault: +%d damage per attack" % count
		"infernal_growth":
			return "Infernal Growth: +1 health when enemy dies nearby"
		"armor":
			return "Armor: -%d damage taken" % count
		"stone_skin":
			return "Stone Skin: +%d health" % (count * 2)
		"fortress":
			return "Fortress: -2 damage taken (4+ Trolls)"
		"regeneration":
			return "Regeneration: +1 health per turn"
		"phase_dodge":
			var dodge_chance = min(count * 15, 75)
			return "Phase Dodge: %d%% chance to avoid damage" % dodge_chance
		"soul_drain":
			return "Soul Drain: +1 health when enemy unit dies"
		"abyssal_power":
			return "Abyssal Power: +2 damage and +2 health"
		"deep_current":
			return "Deep Current: +3 health per turn (4+ Leviathans)"
		_:
			return bonus_name

func ensure_family_display_in_scene():
	"""Make sure the family display is present and visible"""
	var scene_name = "NO_SCENE"
	if get_tree() and get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	print("Family Display: Ensuring display in scene: ", scene_name)
	
	# Check if we already have the persistent display
	if not global_family_display or not is_instance_valid(global_family_display):
		print("Family Display: Creating new persistent display")
		_create_global_family_display()
	else:
		print("Family Display: Display exists, checking visibility")
		# Make sure it's visible and properly positioned
		global_family_display.visible = true
		global_family_display.position = Vector2(20, 50)  # Reset position in case it moved
	
	# Refresh the display
	refresh_global_family_display()
