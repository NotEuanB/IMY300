extends TextureButton

func _ready() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")

func _on_mouse_entered() -> void:
	$FightSprite/FightAnimation.play("Fight_hover")


func _on_mouse_exited() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")
