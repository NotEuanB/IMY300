extends Node2D

func _on_close_button_pressed() -> void:
	queue_free()  # Remove the reward UI from the scene
	emit_signal("tree_exited")  # Notify the parent scene
