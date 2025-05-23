class_name SellPortal
extends Area2D

@export var unit_pool: UnitPool
@export var player_stats: PlayerStats

@onready var gold: HBoxContainer = %Gold
@onready var gold_label: Label = %GoldLabel

var current_unit: Unit

func _ready() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		setup_unit(unit)


func setup_unit(unit: Unit) -> void:
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))


func _sell_unit(unit: Unit) -> void:
	player_stats.gold += unit.stats.gold_cost
	
	unit_pool.add_unit(unit.stats)
	
	unit.queue_free()


func _on_unit_dropped(_starting_position: Vector2, unit: Unit) -> void:
	if unit and unit == current_unit:
		_sell_unit(unit)

func _on_area_entered(unit: Unit) -> void:
	current_unit = unit
	gold_label.text = str(unit.stats.gold_cost)
	gold.show()


func _on_area_exited(unit: Unit) -> void:
	if unit and unit == current_unit:
		current_unit = null
	
	gold.hide()
