extends TextureButton

func _on_mouse_entered() -> void:
	$NewRunSprite/NewRunAnimation.play("NewRun_hover")

func _on_mouse_exited() -> void:
	$NewRunSprite/NewRunAnimation.play("NewRun_idle")
