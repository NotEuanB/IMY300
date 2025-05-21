class_name CombinationPage
extends Control

func _on_decline_button_pressed() -> void:
	self.get_parent().visible = false
	get_parent().get_parent().get_node("ShopUI").visible = true
	
