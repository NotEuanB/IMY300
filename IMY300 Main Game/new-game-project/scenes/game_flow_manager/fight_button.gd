extends TextureButton

func _ready() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")
