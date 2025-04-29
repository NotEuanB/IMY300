extends Node2D

func _ready() -> void:
	# Retrieve inventory and team setup from GameState
	var inventory = GameState.get_inventory()

	print("Loaded inventory: ", inventory)

	# Start the autobattler logic here
	start_autobattler(inventory)

func start_autobattler(team: Array) -> void:
	print("Starting autobattler with team: ", team)
	# Implement your autobattler logic here
