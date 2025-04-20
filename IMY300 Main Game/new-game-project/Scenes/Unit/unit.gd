@tool
class_name Unit
extends Area2D

@export var stats: UnitStats : set = set_stats

@onready var skin: Sprite2D = $Skin
@onready var attack: Label = $StatsContainer/AttackLabel
@onready var health: Label = $StatsContainer/HealthLabel
@onready var drag_and_drop: DragAndDrop = $DragAndDrop

signal hovered(stats: UnitStats)

func set_stats(value: UnitStats) -> void:
	stats = value
	
	if value == null:
		return
	
	if not is_node_ready():
		await ready
	
	attack.text = str(stats.attack)
	health.text = str(stats.health)
	skin.texture = stats.skin


func _on_mouse_entered() -> void:
	if drag_and_drop.dragging:
		return
	
	z_index = 1
	emit_signal("hovered", stats)


func _on_mouse_exited() -> void:
	if drag_and_drop.dragging:
		return
	
	z_index = 0


func reset_after_dragging(starting_position: Vector2) -> void:
	global_position = starting_position
