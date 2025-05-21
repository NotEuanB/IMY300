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


func _ready() -> void:
	player_stats.changed.connect(_on_player_stats_changed)
	self.pressed.connect(_on_pressed)
	_on_player_stats_changed()

func _can_be_bought() -> bool:
	return unit_stats != null and player_stats.gold >= unit_stats.gold_cost and not bought and not hand_full

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
		bought = true
		return
	
	unit_image.texture = unit_stats.skin
	unit_name.text = unit_stats.name
	unit_atk.text = str(unit_stats.attack)
	unit_hp.text = str(unit_stats.health)
	unit_description.text = unit_stats.description


func _on_player_stats_changed() -> void:
	if not unit_stats:
		return
	
	var has_enough_gold := player_stats.gold >= unit_stats.gold_cost
	disabled = not has_enough_gold or hand_full or bought
	
	if not disabled:
		modulate = Color(Color.WHITE, 1.0)
	else:
		modulate = Color(Color.WHITE, 0.5)


func _on_pressed() -> void:
	if bought or disabled:
		return
	
	bought = true
	placeholder.show()
	player_stats.gold -= unit_stats.gold_cost
	unit_bought.emit(unit_stats)
