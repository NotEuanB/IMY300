extends TextureButton

func _on_mouse_entered() -> void:
	$CreditsSprite/CreditsAnimation.play("Credits_hover")

func _on_mouse_exited() -> void:
	$CreditsSprite/CreditsAnimation.play("Credits_idle")
