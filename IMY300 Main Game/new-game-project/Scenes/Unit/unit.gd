@tool
class_name Unit
extends Area2D

@export var stats: Resource : set = set_stats

@onready var skin: Sprite2D = $Skin
@onready var drag_and_drop: DragAndDrop = $DragAndDrop
@onready var unit_atk: RichTextLabel = $Stats/AttackStat
@onready var unit_hp: RichTextLabel = $Stats/HealthStat
@onready var unit_name: Label = $Stats/Name
@onready var unit_description: Label = $Stats/Description

signal hovered(stats)
signal selected(unit)

var selectable: bool = false
var enabled: bool = true

# Add these properties to store original stats and max health
var original_stats: Resource
var base_attack: int
var base_health: int
var max_health_reached: int = 0  # Track the highest health this unit has ever had

func set_selectable(value: bool) -> void:
	selectable = value
	modulate = Color(1, 0.5, 1, 1) if value else Color(1, 1, 1, 1)

func set_enabled(value: bool) -> void:
	enabled = value

func _input_event(_viewport, event, _shape_idx):
	if not enabled:
		return
	
	if selectable and event is InputEventMouseButton and event.pressed:
		emit_signal("selected", self)

func set_stats(value: Resource) -> void:
	stats = value
	
	if value == null:
		return
	
	# Initialize base stats in the UnitStats if not already set
	if value.has_method("initialize_base_stats"):
		value.initialize_base_stats()
	
	# Use base stats from the UnitStats resource
	if value.has_method("get") and "base_attack" in value:
		base_attack = value.base_attack
		base_health = value.base_health
	else:
		# Fallback if UnitStats doesn't have base stats yet
		base_attack = value.attack
		base_health = value.health
	
	# Track the maximum health this unit has reached
	if stats.health > max_health_reached:
		max_health_reached = stats.health
	
	
	if not is_node_ready():
		await ready
	
	# Check if nodes exist before using them
	if skin:
		skin.texture = stats.skin
	if unit_name:
		unit_name.text = stats.name
	
	# Always update visual formatting
	if unit_atk and base_attack > 0:
		update_stat_display_attack(unit_atk, stats.attack, base_attack)
	if unit_hp and base_health > 0:
		update_stat_display_health(unit_hp, stats.health, base_health, max_health_reached)
	
	if unit_description:
		unit_description.text = stats.description

func update_stat_display_attack(label: RichTextLabel, current_value: int, base_value: int) -> void:
	if not label:
		print("Label is null!")
		return
	
	# Ensure BBCode is enabled
	label.bbcode_enabled = true
	
	
	if current_value > base_value:
		# Dark green, bold, and larger for increased stats
		label.text = "[color=#006400][b][font_size=20]" + str(current_value) + "[/font_size][/b][/color]"
	elif current_value < base_value:
		# Dark red, bold, and larger for decreased stats
		label.text = "[color=#4A0000[b][font_size=20]" + str(current_value) + "[/font_size][/b][/color]"
	else:
		# Black for normal/base stats
		label.text = "[color=black]" + str(current_value) + "[/color]"

func update_stat_display_health(label: RichTextLabel, current_value: int, base_value: int, max_value: int) -> void:
	if not label:
		print("Label is null!")
		return
	
	# Ensure BBCode is enabled
	label.bbcode_enabled = true
	
	
	if current_value < max_value:
		# Very dark red/maroon for damaged health - readable on light red background
		label.text = "[color=#2B0000][b][font_size=20]" + str(current_value) + "[/font_size][/b][/color]"
	elif current_value > base_value:
		# Green if health is above base value (buffed)
		label.text = "[color=#006400][b][font_size=20]" + str(current_value) + "[/font_size][/b][/color]"
	else:
		# Black for normal/base health
		label.text = "[color=black]" + str(current_value) + "[/color]"


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

func _ready() -> void:
	if stats:
		call_deferred("refresh_stats_display")
		
func refresh_stats_display() -> void:
	
	if stats and unit_atk and unit_hp and base_attack > 0:
		update_stat_display_attack(unit_atk, stats.attack, base_attack)
		update_stat_display_health(unit_hp, stats.health, base_health, max_health_reached)
	else:
		print("Conditions not met for refresh")
