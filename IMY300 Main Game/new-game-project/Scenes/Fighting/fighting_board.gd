extends Node2D

@export var max_board_units: int = 6  # Maximum number of units on the board

@onready var player_area: PlayArea = $PlayerArea
@onready var hand_area: PlayArea = $HandArea
@onready var enemy_area: PlayArea = $EnemyArea

# Preload the Unit.tscn scene
var unit_scene = preload("res://Scenes/Unit/unit.tscn")

func _ready():
	# Debug: Ensure PlayerArea and HandArea are assigned
	if player_area == null or hand_area == null:
		print("Error: PlayerArea or HandArea node not found!")
		return
	
	print("PlayerArea and HandArea assigned successfully.")
	print("Inventory in fighting scene: ", GameState.get_inventory())
	
	# Populate the player's board and hand with units from the inventory
	populate_board_and_hand()

func populate_board_and_hand():
	var inventory = GameState.get_inventory()  # Get the player's inventory
	var board_units = inventory.slice(0, max_board_units)  # Units for the board
	var hand_units = inventory.slice(max_board_units, inventory.size())  # Remaining units for the hand
	
	# Populate the board
	for unit_stats in board_units:
		spawn_unit_on_board(unit_stats)
	
	# Populate the hand
	for unit_stats in hand_units:
		spawn_unit_in_hand(unit_stats)
	
	# Clear the inventory after placing units
	GameState.inventory.clear()
	print("Inventory cleared after placement.")

func spawn_unit_on_board(unit_stats: UnitStats):
	var empty_tile = player_area.unit_grid.get_first_empty_tile()
	if empty_tile != Vector2i(-1, -1):  # Ensure there's an empty tile
		var unit_instance = unit_scene.instantiate()  # Create an instance of the Unit.tscn scene
		unit_instance.stats = unit_stats  # Assign the UnitStats directly
		player_area.unit_grid.add_unit(empty_tile, unit_instance)
		unit_instance.global_position = player_area.get_global_from_tile(empty_tile)
		add_child(unit_instance)
		print("Unit placed on board: ", unit_stats.name, " at tile: ", empty_tile)

func spawn_unit_in_hand(unit_stats: UnitStats):
	var empty_tile = hand_area.unit_grid.get_first_empty_tile()
	if empty_tile != Vector2i(-1, -1):  # Ensure there's an empty tile
		var unit_instance = unit_scene.instantiate()  # Create an instance of the Unit.tscn scene
		unit_instance.stats = unit_stats  # Assign the UnitStats directly
		hand_area.unit_grid.add_unit(empty_tile, unit_instance)
		unit_instance.global_position = hand_area.get_global_from_tile(empty_tile)
		add_child(unit_instance)
		print("Unit placed in hand: ", unit_stats.name, " at tile: ", empty_tile)
