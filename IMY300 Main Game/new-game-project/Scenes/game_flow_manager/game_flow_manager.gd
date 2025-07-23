extends Control

enum GameStep { STEP_1, STEP_2, FIGHT }

var current_step: GameStep = GameStep.STEP_1



func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	# Hide all buttons initially
	$VBoxContainer/ShopButton.visible = false
	$VBoxContainer/CombineButton.visible = false
	$VBoxContainer/FightButton.visible = false

	# Show buttons based on the current step
	match current_step:
		GameStep.STEP_1, GameStep.STEP_2:
			$VBoxContainer/ShopButton.visible = true
			$VBoxContainer/CombineButton.visible = true
		GameStep.FIGHT:
			$VBoxContainer/FightButton.visible = true

func _on_ShopButton_pressed() -> void:
	# Load the Shop scene
	_load_scene("res://Scenes/Board/board.tscn")

func _on_CombineButton_pressed() -> void:
	# Load the Combine scene
	_load_scene("res://Scenes/combine_board/combineboard.tscn")

func _on_FightButton_pressed() -> void:
	# Load the Fight scene
	_load_scene("res://Scenes/forest_board/forestboard.tscn")

func _load_scene(scene_path: String) -> void:
	print("Attempting to load scene:", scene_path)
	var scene = load(scene_path)
	if scene == null:
		print("Error: Scene not found or failed to load at path:", scene_path)
		return
	var instance = scene.instantiate()
	if instance == null:
		print("Error: Failed to instantiate scene:", scene_path)
		return
	get_tree().root.add_child(instance)
	instance.connect("tree_exited", Callable(self, "_on_scene_exited"))

func _on_scene_exited() -> void:
	# Update the game step after the player exits a scene
	match current_step:
		GameStep.STEP_1:
			current_step = GameStep.STEP_2
		GameStep.STEP_2:
			current_step = GameStep.FIGHT
	_update_ui()
