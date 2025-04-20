class_name ShopContainter
extends Control

signal unit_bought(unit: UnitStats)

const UNIT_CARD = preload("res://Scenes/UnitCard/unit_card.tscn")

@export var unit_pool: UnitPool
@export var player_stats: PlayerStats

@onready var shop_cards: HBoxContainer = $Bottom

func _ready() -> void:
	unit_pool.generate_unit_pool()
	
	for child: Node in shop_cards.get_children():
		child.queue_free()
	
	_roll_units()


func _roll_units() -> void:
	for i in 5:
		var new_card: UnitCard = UNIT_CARD.instantiate()
		new_card.unit_stats = unit_pool.get_random_unit()
		new_card.unit_bought.connect(_on_unit_bought)
		shop_cards.add_child(new_card)


func _put_back_remaining_to_pool() -> void:
	for unit_card: UnitCard in shop_cards.get_children():
		if not unit_card.bought:
			unit_pool.add_unit(unit_card.unit_stats)
		
		unit_card.queue_free()

func _on_unit_bought(unit: UnitStats) -> void:
	unit_bought.emit(unit)

func _on_reroll_button_pressed() -> void:
	print(unit_pool.unit_pool)
	_put_back_remaining_to_pool()
	print(unit_pool.unit_pool)
	_roll_units()
