class_name UnitCard
extends Button

signal unit_bought(unit: UnitStats)

@export var player_stats: PlayerStats
@export var unit_stats: UnitStats : set = _set_unit_stats

@onready var traits: Label = %Traits
@onready var bottom: Panel = %Bottom
@onready var unit_name: Label = %UnitName
@onready var gold_label: Label = %GoldLabel
@onready var unit_icon: TextureRect = $UnitIcon
@onready var placeholder: Panel = %Placeholder

var bought := false

func _ready() -> void:
	player_stats.changed.connect(_on_player_stats_changed)
	_on_player_stats_changed()
	
	unit_bought.connect(
		func(unit: UnitStats):
			print("bought unit: ", unit)
			print("gold: ", player_stats.gold)
	)


func _set_unit_stats(value: UnitStats) -> void:
	unit_stats = value
	
	if not is_node_ready():
		await ready
	
	if not unit_stats:
		placeholder.show()
		disabled = true
		bought = true
		return
	
	traits.text = str(unit_stats.attack) + " ATK\n" + str(unit_stats.health) + " HP" 
	unit_name.text = unit_stats.name
	gold_label.text = str(unit_stats.gold_cost)
	unit_icon.texture = unit_stats.skin

func _on_player_stats_changed() -> void:
	if not unit_stats:
		return
	
	var has_enough_gold := player_stats.gold >= unit_stats.gold_cost
	disabled = not has_enough_gold
	
	if has_enough_gold or bought:
		modulate = Color(Color.WHITE, 1.0)
	else:
		modulate = Color(Color.WHITE, 0.5)


func _on_pressed() -> void:
	if bought:
		return
	
	bought = true
	placeholder.show()
	player_stats.gold -= unit_stats.gold_cost
	unit_bought.emit(unit_stats)
