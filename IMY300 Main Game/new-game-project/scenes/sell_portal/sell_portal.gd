class_name SellPortal
extends Area2D

@export var unit_pool: UnitPool
@export var player_stats: PlayerStats

@onready var gold: HBoxContainer = %Gold
@onready var gold_label: Label = %GoldLabel

var current_unit: Unit
var enabled = true

func _ready() -> void:
	# Connect to existing units with a delay to ensure they're ready
	call_deferred("_setup_existing_units")
	
	# Connect to new units that might be spawned
	get_tree().node_added.connect(_on_node_added)

func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled

func _setup_existing_units() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		call_deferred("setup_unit", unit)

func _on_node_added(node: Node) -> void:
	# Auto-setup new units that are added to the scene
	if node.is_in_group("units") and node is Unit:
		call_deferred("setup_unit", node as Unit)

func setup_unit(unit: Unit) -> void:
	# Check if drag_and_drop exists before accessing it
	if not unit.drag_and_drop:
		print("Warning: Unit ", unit.name, " has no drag_and_drop component")
		return
	
	# Disconnect first to avoid duplicate connections
	if unit.drag_and_drop.dropped.is_connected(_on_unit_dropped):
		unit.drag_and_drop.dropped.disconnect(_on_unit_dropped)
	
	# Connect the signal with the unit bound
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))

signal unit_sold(unit: Unit)

func _sell_unit(unit: Unit) -> void:
	if not enabled:
		return
		
	player_stats.gold += unit.stats.gold_cost
	player_stats.changed.emit() # Make sure to emit the change signal
	
	unit_pool.add_unit(unit.stats)
	
	# Remove unit from grid if it's in one
	if unit.get_parent() and unit.get_parent().has_method("remove_unit"):
		var grid = unit.get_parent()
		for tile in grid.units.keys():
			if grid.units[tile] == unit:
				grid.remove_unit(tile)
				break
	
	# Emit signal for tutorial advancement
	unit_sold.emit(unit)
	
	unit.queue_free()

func _on_unit_dropped(_starting_position: Vector2, unit: Unit) -> void:
	if not enabled:
		return
		
	if unit and unit == current_unit:
		_sell_unit(unit)

func _on_area_entered(unit: Unit) -> void:
	if not enabled:
		return
		
	current_unit = unit
	if unit and unit.stats:
		gold_label.text = str(unit.stats.gold_cost)
		gold.show()

func _on_area_exited(unit: Unit) -> void:
	if unit and unit == current_unit:
		current_unit = null
	
	gold.hide()
