extends TextureButton

signal fight_pressed

func _ready() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")

func _on_pressed() -> void:
	emit_signal("fight_pressed")
	$Button.play()
