extends TextureButton

func _on_mouse_entered() -> void:
	$ContinueSprite/ContinueAnimation.play("Continue_hover")

func _on_mouse_exited() -> void:
	$ContinueSprite/ContinueAnimation.play("Continue_idle")
