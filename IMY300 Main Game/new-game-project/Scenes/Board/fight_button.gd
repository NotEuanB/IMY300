extends TextureButton

func _ready() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")

func _on_mouse_entered() -> void:
	$FightSprite/FightAnimation.play("Fight_hover")


func _on_mouse_exited() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")

func _on_pressed() -> void:
	$FightSprite/FightAnimation.play("Fight_press")
	await get_tree().create_timer(0.5).timeout  
	emit_signal("mouse_entered")  
