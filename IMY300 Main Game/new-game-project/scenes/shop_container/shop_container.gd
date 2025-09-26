class_name ShopContainer
extends Control

signal unit_bought(unit: UnitStats)

const UNIT_CARD = preload("res://scenes/unit_card/unit_card.tscn")

var purchasing_enabled = true

@export var unit_pool: UnitPool
@export var player_stats: PlayerStats
@export var unit_spawner: UnitSpawner

@onready var shop_cards: HBoxContainer = $Bottom

func _ready() -> void:
	# Use the global unit pool instead of the local one
	unit_pool = GameState.get_unit_pool()
	

	
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

func _is_unit_valid_for_round(unit_stats: UnitStats, current_round: int) -> bool:
	var tier = unit_stats.tier
	
	match tier:
		1: # Tier 1 - always valid (early game)
			return true
		2: # Tier 2 - valid from round 3+
			return current_round >= 3
		3: # Tier 3 - valid from round 5+
			return current_round >= 5
		4: # Tier 4 - valid from round 7+ (endgame units)
			return current_round >= 7
		_:
			return true

func _roll_units() -> void:
	# Store current units to put back in pool - but only if they're valid for current round
	var current_units = []
	for card in shop_cards.get_children():
		if card.visible and card.unit_stats:
			# Check if this unit should exist in the current round
			var is_valid_for_round = _is_unit_valid_for_round(card.unit_stats, GameState.main_round)
			if is_valid_for_round:
				current_units.append(card.unit_stats)
	
	# Put back units to pool before clearing
	for unit in current_units:
		unit_pool.add_unit(unit)
	
	# Clear existing cards
	for child: Node in shop_cards.get_children():
		child.queue_free()
	
	# Wait for the queue_free to process
	await get_tree().process_frame
	

	
	# Show all combined units in the pool
	var combined_units = []
	for unit in unit_pool.unit_pool:
		if not unit.name in ["Rat", "Golem", "Flame Imp", "Moss Troll", "Spectre"]:  # Add your base unit names
			combined_units.append(unit.name)
	

	
	# Get which slots should be active
	var active_slots = get_shop_slot_positions()

	
	# Create and populate cards for active slots only
	for i in 6:
		var new_card: UnitCard = UNIT_CARD.instantiate()
		shop_cards.add_child(new_card)
		
		if i in active_slots:
			var unit = unit_pool.get_random_unit()

			if unit:
				new_card.unit_stats = unit
				new_card.player_stats = player_stats
				new_card.unit_bought.connect(_on_unit_bought)
				new_card.visible = true
			else:
				new_card.visible = false
		else:
			new_card.visible = false
	
	if unit_spawner:
		var is_full = unit_spawner.hand_area.unit_grid.is_grid_full()
		set_hand_full(is_full)
	
	# Apply the current purchasing state to new cards
	for child in shop_cards.get_children():
		if child is UnitCard:
			child.set_buy_enabled(purchasing_enabled)

func get_shop_slot_positions() -> Array[int]:
	var current_round = GameState.main_round if GameState.game_mode == GameState.GameMode.MAIN_GAME else 1
	
	match current_round:
		1:
			return [2, 3]  # Middle 2 slots
		2:
			return [1, 2, 3, 4]  # Middle 4 slots
		_:
			return [0, 1, 2, 3, 4, 5]  # All 6 slots

func set_purchasing_enabled(enabled: bool) -> void:
	purchasing_enabled = enabled

	
	# Enable/disable all unit cards in the shop
	for child in shop_cards.get_children():
		if child is UnitCard:
			child.set_buy_enabled(enabled)

func _on_unit_bought(unit: UnitStats) -> void:
	# Check if purchasing is enabled
	if not purchasing_enabled:
		return
		
	if player_stats.gold < unit.gold_cost:
		return
	
	player_stats.gold -= unit.gold_cost
	player_stats.changed.emit()
	
	# Remove the unit from the pool only when bought
	unit_pool.remove_unit_from_pool(unit)
	
	unit_bought.emit(unit)

func _on_reroll_button_pressed() -> void:
	if player_stats.gold >= 1:
		player_stats.gold -= 1
		player_stats.changed.emit()
		
		# The _roll_units function now handles putting units back
		_roll_units()
