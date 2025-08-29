extends Control

func _ready() -> void:
	$MainMenuAnimation/MainMenuAnimation.play("MainMenu_idle")


func _on_new_run_button_pressed() -> void:
	GameState.start_main_game()
	get_tree().change_scene_to_file("res://scenes/game_flow_manager/GameFlowManager.tscn")
