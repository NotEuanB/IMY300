extends TextureButton

func _ready() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")

func _on_pressed() -> void:
	$CombineSprite/CombineAnimation.play("Combine_press")
	await get_tree().create_timer(2.5).timeout
	# Get the current scene tree
	var scene_tree = get_tree()
	# Change to the new scene
	scene_tree.change_scene_to_file("res://Scenes/ForestBoard/forestboard.tscn")

func _on_mouse_entered() -> void:
	$CombineSprite/CombineAnimation.play("Combine_hover")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_hover")

func _on_mouse_exited() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_idle")
