extends TextureButton

func _ready() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")

func _on_pressed() -> void:
	$FightSprite/FightAnimation.play("Fight_press")
	# Get the current scene tree
	var scene_tree = get_tree()
	# Change to the new scene
	scene_tree.change_scene_to_file("res://Scenes/CombineBoard/combineboard.tscn")


func _on_mouse_entered() -> void:
	$FightSprite/FightAnimation.play("Fight_hover")

func _on_mouse_exited() -> void:
	$FightSprite/FightAnimation.play("Fight_idle")
