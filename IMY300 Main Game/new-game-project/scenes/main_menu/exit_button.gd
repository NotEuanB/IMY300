extends TextureButton

func _on_mouse_entered() -> void:
	$ExitSprite/ExitAnimation.play("Exit_hover")

func _on_mouse_exited() -> void:
	$ExitSprite/ExitAnimation.play("Exit_idle")


func _on_pressed() -> void:
	$"../CreditsButton/Button".play()
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()
