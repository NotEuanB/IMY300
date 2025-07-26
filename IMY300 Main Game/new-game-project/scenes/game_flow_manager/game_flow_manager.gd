extends Control

@onready var tutorial_popup = $TutorialPopup
@onready var tutorial_text = $TutorialPopup/TutorialText

func _ready() -> void:
	_update_ui()
	_show_tutorial_popup()

func _show_tutorial_popup() -> void:
	tutorial_text.text = "Welcome to the game! Here are your options:\n\n- Shop: Buy units.\n- Combine: Combine units.\n- Fight: Start a battle.\n\nPress the Shop button to begin."
	$TutorialPopup.visible = true  # Show the tutorial panel

func _update_ui() -> void:
	# Hide all buttons initially
	$VBoxContainer/ShopButton.visible = false
	$VBoxContainer/CombineButton.visible = false
	$VBoxContainer/FightButton.visible = false

	# Show buttons based on the current step
	match GameState.current_step:
		GameState.GameStep.STEP_1:
			$VBoxContainer/ShopButton.visible = true
			$VBoxContainer/CombineButton.visible = true
			$VBoxContainer/CombineButton.disabled = true
		GameState.GameStep.STEP_2:
			$VBoxContainer/ShopButton.visible = true
			$VBoxContainer/CombineButton.visible = true
		GameState.GameStep.FIGHT:
			$VBoxContainer/ShopButton.visible = false
			$VBoxContainer/CombineButton.visible = false
			$VBoxContainer/FightButton.visible = true

func _on_ShopButton_pressed() -> void:
	# Load the Shop scene
	tutorial_popup.hide()
	_load_scene("res://Scenes/Board/board.tscn")

func _on_CombineButton_pressed() -> void:
	# Load the Combine scene
	_load_scene("res://Scenes/combine_board/combineboard.tscn")

func _on_FightButton_pressed() -> void:
	# Load the Fight scene
	_load_scene("res://Scenes/forest_board/forestboard.tscn")

func _load_scene(scene_path: String) -> void:
	print("Changing scene to:", scene_path)
	GameState.update_step()  # Centralized game step update
	get_tree().change_scene_to_file(scene_path)
	_update_ui()
