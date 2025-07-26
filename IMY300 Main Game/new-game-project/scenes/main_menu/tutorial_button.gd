extends TextureButton

func _on_pressed() -> void:
	$"../CreditsButton/Button".play()
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/game_flow_manager/GameFlowManager.tscn")


func _on_mouse_entered() -> void:
	$TutorialSprite/TutorialAnimation.play("Tutorial_hover")

func _on_mouse_exited() -> void:
	$TutorialSprite/TutorialAnimation.play("Tutorial_idle")
