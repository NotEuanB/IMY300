class_name ShopContainer
extends Control

signal unit_bought(unit: UnitStats)

const UNIT_CARD = preload("res://scenes/unit_card/unit_card.tscn")

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
		# Don't override the modulate here - let the card handle its own visual state
		# unit_card.disabled = is_full
		# unit_card.modulate = Color(1, 1, 1, 0.5) if is_full else Color(1, 1, 1, 1)
		
		# Instead, trigger the card's own update function
		if unit_card.has_method("_on_player_stats_changed"):
			unit_card._on_player_stats_changed()

func _roll_units() -> void:
	# Clear existing cards first
	for child: Node in shop_cards.get_children():
		child.queue_free()
	
	# Wait for the queue_free to process
	await get_tree().process_frame
	
	# Create 6 placeholder cards
	for i in 6:
		var new_card: UnitCard = UNIT_CARD.instantiate()
		shop_cards.add_child(new_card)
	
	# Get which slots should be active
	var active_slots = get_shop_slot_positions()
	
	# Populate only the active slots
	for i in 6:
		var card = shop_cards.get_child(i)
		if i in active_slots:
			# Get a unit from the pool
			var unit = unit_pool.get_random_unit()
			if unit:  # Check if we actually got a unit
				# Populate this slot with a real unit
				card.unit_stats = unit
				card.player_stats = player_stats
				card.unit_bought.connect(_on_unit_bought)
				card.visible = true
			else:
				# No units available, hide the slot
				card.visible = false
		else:
			# Make this an empty/hidden slot
			card.visible = false
	
	if unit_spawner:
		var is_full = unit_spawner.hand_area.unit_grid.is_grid_full()
		set_hand_full(is_full)

func get_shop_slot_positions() -> Array[int]:
	var current_round = GameState.main_round if GameState.game_mode == GameState.GameMode.MAIN_GAME else 1
	
	match current_round:
		1:
			return [2, 3]  # Middle 2 slots
		2:
			return [1, 2, 3, 4]  # Middle 4 slots
		_:
			return [0, 1, 2, 3, 4, 5]  # All 6 slots

func _put_back_remaining_to_pool() -> void:
	for unit_card: UnitCard in shop_cards.get_children():
		if not unit_card.bought:
			unit_pool.add_unit(unit_card.unit_stats)
		
		unit_card.queue_free()

func _on_unit_bought(unit: UnitStats) -> void:
	# Check if player has enough gold (safety check)
	if player_stats.gold < unit.gold_cost:
		print("Not enough gold to buy this unit!")
		return
	
	# Deduct gold and emit the signal
	print("Gold before purchase:", player_stats.gold)
	player_stats.gold -= unit.gold_cost
	print("Gold after purchase:", player_stats.gold)
	player_stats.changed.emit()
	
	# Emit the unit_bought signal to the board
	unit_bought.emit(unit)

func _on_reroll_button_pressed() -> void:
	if player_stats.gold >= 2:
		player_stats.gold -= 2  # ADD THIS LINE - you're missing the gold deduction
		player_stats.changed.emit()
		print(unit_pool.unit_pool)
		_put_back_remaining_to_pool()
		print(unit_pool.unit_pool)
		_roll_units()
