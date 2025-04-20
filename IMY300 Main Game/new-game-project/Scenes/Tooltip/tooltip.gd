class_name TooltipClass
extends Control

@onready var unit_image: TextureRect = $UnitImage
@onready var unit_name: Label = $UnitLabel


func show_unit_tooltip(stats: UnitStats) -> void:
	unit_image.texture = stats.portrait
	unit_name.text = stats.description
	unit_image.scale = Vector2(0.08, 0.08)
	show()

func hide_tooltip() -> void:
	hide()
