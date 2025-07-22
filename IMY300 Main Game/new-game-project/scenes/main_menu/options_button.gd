extends TextureButton

func _on_mouse_entered() -> void:
	$OptionsSprite/OptionsAnimation.play("Options_hover")

func _on_mouse_exited() -> void:
	$OptionsSprite/OptionsAnimation.play("Options_idle")
