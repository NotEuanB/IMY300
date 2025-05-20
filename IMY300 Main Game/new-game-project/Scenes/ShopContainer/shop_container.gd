class_name ShopContainer
extends Control

signal unit_bought(unit: UnitStats)

const UNIT_CARD = preload("res://Scenes/UnitCard/unit_card.tscn")

@export var unit_pool: UnitPool
@export var player_stats: PlayerStats
@export var unit_spawner: UnitSpawner

@onready var shop_cards: HBoxContainer = $Bottom

func _ready() -> void:
	unit_pool.generate_unit_pool()
	
	for child: Node in shop_cards.get_children():
		child.queue_free()
	
	_roll_units()

	if unit_spawner:
		unit_spawner.hand_full_changed.connect(set_hand_full)
	
func set_hand_full(is_full: bool) -> void:
	for unit_card: UnitCard in shop_cards.get_children():
		unit_card.hand_full = is_full
		unit_card.disabled = is_full
		unit_card.modulate = Color(1, 1, 1, 0.5) if is_full else Color(1, 1, 1, 1)

func _roll_units() -> void:
	for i in 6:
		var new_card: UnitCard = UNIT_CARD.instantiate()
		new_card.unit_stats = unit_pool.get_random_unit()
		new_card.unit_bought.connect(_on_unit_bought)
		shop_cards.add_child(new_card)
	
	if unit_spawner:
		var is_full = unit_spawner.hand_area.unit_grid.is_grid_full()
		set_hand_full(is_full)


func _put_back_remaining_to_pool() -> void:
	for unit_card: UnitCard in shop_cards.get_children():
		if not unit_card.bought:
			unit_pool.add_unit(unit_card.unit_stats)
		
		unit_card.queue_free()

func _on_unit_bought(unit: UnitStats) -> void:
	unit_bought.emit(unit)

func _on_reroll_button_pressed() -> void:
	if player_stats.gold >= 2:
		player_stats.changed.emit()
		print(unit_pool.unit_pool)
		_put_back_remaining_to_pool()
		print(unit_pool.unit_pool)
		_roll_units()
