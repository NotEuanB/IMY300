extends TextureButton

func _on_mouse_entered() -> void:
	$NewRunSprite/NewRunAnimation.play("NewRun_hover")

func _on_mouse_exited() -> void:
	$NewRunSprite/NewRunAnimation.play("NewRun_idle")

func _on_pressed() -> void:
	$"../CreditsButton/Button".play()
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/board/board.tscn")
