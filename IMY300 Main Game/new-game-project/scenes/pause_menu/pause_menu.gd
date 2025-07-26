extends Control

@onready var main = $"../../"
var player_stats = load("res://data/player/player_stats.tres")

func _on_resume_pressed() -> void:
	main.pauseMenu()

func _on_quit_pressed() -> void:
	player_stats.reset_stats()
	GameState.reset_state()
	GameState.reset_step()
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
