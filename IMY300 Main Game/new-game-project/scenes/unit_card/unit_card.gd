class_name UnitCard
extends Button

signal unit_bought(unit: UnitStats)

@export var player_stats: PlayerStats
@export var unit_stats: UnitStats : set = _set_unit_stats

@onready var unit_image: TextureRect = $CardBackground/UnitImage
@onready var placeholder: Panel = %Placeholder
@onready var unit_atk: Label = $Stats/AttackStat
@onready var unit_hp: Label = $Stats/HealthStat
@onready var unit_name: Label = $Stats/Name
@onready var unit_description: Label = $Stats/Description

var bought := false
var hand_full: bool = false:
	set = set_hand_full
var buy_enabled := true


func _ready() -> void:
	player_stats.changed.connect(_on_player_stats_changed)
	self.pressed.connect(_on_pressed)
	_on_player_stats_changed()

func _can_be_bought() -> bool:
	return unit_stats != null and player_stats.gold >= unit_stats.gold_cost and not bought and not hand_full and buy_enabled

func set_hand_full(value: bool) -> void:
	hand_full = value
	_on_player_stats_changed()

func _set_unit_stats(value: UnitStats) -> void:
	unit_stats = value
	
	if not is_node_ready():
		await ready
	
	if not unit_stats:
		placeholder.show()
		disabled = true
		# Don't set bought = true here - this makes it appear as a bought card
		# bought = true  # REMOVE THIS LINE
		return
	
	# Hide placeholder when we have valid unit stats
	placeholder.hide()
	disabled = false
	bought = false  # Reset bought state
	
	unit_image.texture = unit_stats.skin
	unit_name.text = unit_stats.name
	unit_atk.text = str(unit_stats.attack)
	unit_hp.text = str(unit_stats.health)
	unit_description.text = unit_stats.description
	$TextureRect/Coin.text = str(unit_stats.gold_cost)

func _on_player_stats_changed() -> void:
	if not unit_stats:
		return
	
	var has_enough_gold := player_stats.gold >= unit_stats.gold_cost
	
	# Dim the card if:
	# 1. It's already bought, OR
	# 2. Player doesn't have enough gold, OR  
	# 3. Hand is full, OR
	# 4. Buying is disabled (tutorial)
	if bought or not has_enough_gold or hand_full or not buy_enabled:
		disabled = true
		modulate = Color(Color.WHITE, 0.5)
	else:
		disabled = false
		modulate = Color(Color.WHITE, 1.0)


func _on_pressed() -> void:
	if bought or disabled or not _can_be_bought() or not buy_enabled:
		print("Purchase blocked - bought:", bought, " disabled:", disabled, " can_be_bought:", _can_be_bought(), " buy_enabled:", buy_enabled)
		return
	
	# Don't deduct gold here - let shop_container handle it
	bought = true
	placeholder.show()
	unit_bought.emit(unit_stats)
	$Buy.play()
	$TextureRect.visible = false

func set_buy_enabled(enabled: bool) -> void:
	buy_enabled = enabled
	
	# Visual feedback - make it semi-transparent when disabled
	if enabled:
		modulate = Color(1, 1, 1, 1)  # Fully opaque
	else:
		modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
	
	# Update the disabled state
	_on_player_stats_changed()
