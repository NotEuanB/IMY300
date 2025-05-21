@tool
class_name Unit
extends Area2D

@export var stats: UnitStats : set = set_stats

@onready var skin: Sprite2D = $Skin
@onready var drag_and_drop: DragAndDrop = $DragAndDrop
@onready var unit_atk: Label = $Stats/AttackStat
@onready var unit_hp: Label = $Stats/HealthStat
@onready var unit_name: Label = $Stats/Name
@onready var unit_description: Label = $Stats/Description

signal hovered(stats: UnitStats)
signal selected(unit)

var selectable: bool = false

func _ready():
	print_tree_pretty()
	print("unit_description: ", unit_description)

func set_selectable(value: bool) -> void:
	selectable = value
	modulate = Color(1, 0.5, 1, 1) if value else Color(1, 1, 1, 1)

func _input_event(_viewport, event, _shape_idx):
	if selectable and event is InputEventMouseButton and event.pressed:
		emit_signal("selected", self)

func set_stats(value: UnitStats) -> void:
	stats = value
	
	if value == null:
		return
	
	if not is_node_ready():
		await ready
	
	skin.texture = stats.skin
	unit_name.text = stats.name
	unit_atk.text = str(stats.attack)
	unit_hp.text = str(stats.health)
	if unit_description:
		unit_description.text = stats.description


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


func on_played(_play_area: PlayArea) -> void:
	pass
