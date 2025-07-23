class_name Shop
extends Node2D

const CELL_SIZE := Vector2(180, 305)

@onready var unit_mover: UnitMover = $UnitMover
@onready var unit_spawner: UnitSpawner = $UnitSpawner
@onready var sell_portal: SellPortal = $SellPortal
@onready var tooltip: TooltipClass = $Tooltip  # Ensure TooltipClass node exists
@onready var shop_container: ShopContainer = $ShopContainer
@onready var board_area: PlayArea = $PlayArea
@onready var hand_area: PlayArea = $HandArea
@onready var pause_menu = $PauseMenu
var paused = false

var hovered_unit: Node = null  # To store the currently hovered unit
var time_hover_started: float = -1.0  # To track the time when hover started (in milliseconds)
var hover_delay: float = 1000.0  # 1 second delay before showing tooltip (in milliseconds)

func _ready() -> void:
	unit_spawner.unit_spawned.connect(unit_mover.setup_unit)
	unit_spawner.unit_spawned.connect(sell_portal.setup_unit)
	shop_container.unit_bought.connect(_on_unit_bought)
	$FightButton.fight_pressed.connect(_on_fight_button_pressed)

func _on_unit_bought(unit_stats: UnitStats) -> void:
	unit_spawner.spawn_unit(unit_stats)

# Tooltip handlers
func _on_unit_hovered(unit: Node) -> void:
	# Only start the hover tracking if the unit is not being dragged
	var drag_and_drop = unit.get_node("DragAndDrop")
	if drag_and_drop and drag_and_drop.dragging:
		return  # Don't show tooltip if unit is being dragged

	hovered_unit = unit  # Store the currently hovered unit
	time_hover_started = Time.get_ticks_msec()  # Start tracking hover time (in milliseconds)


func _on_unit_exited(_unit: Node) -> void:
	# Hide the tooltip when mouse exits the unit
	tooltip.hide_tooltip()  # Ensure tooltip is hidden when exiting
	hovered_unit = null
	time_hover_started = -1.0  # Reset the hover timer


# Drag event handlers
func _on_unit_drag_started() -> void:
	# Hide the tooltip when the unit starts dragging
	tooltip.hide_tooltip()  # Hide the tooltip during dragging

func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	
	paused = !paused

# Check the hover time each frame
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
		
	if hovered_unit != null and time_hover_started >= 0:
		# Calculate how much time has passed since hover started (in milliseconds)
		var hover_duration = Time.get_ticks_msec() - time_hover_started
		
		if hover_duration >= hover_delay:
			# Ensure unit is not being dragged before showing tooltip
			var drag_and_drop = hovered_unit.get_node("DragAndDrop")  # Adjust path as needed
			if drag_and_drop and drag_and_drop.dragging:
				return  # Do not show tooltip if unit is being dragged

			# Show the tooltip after the delay
			var unit_stats = hovered_unit.stats  # Assuming unit has a 'stats' variable with relevant data
			tooltip.show_unit_tooltip(unit_stats)  # Show the unit's name and image
			tooltip.global_position = get_global_mouse_position() + Vector2(16, 16)  # Position the tooltip near the mouse
			time_hover_started = -1.0  # Reset so the tooltip isn't shown again

func get_hand_state() -> Array:
	var hand = []
	for tile in unit_spawner.hand_area.unit_grid.units:
		var unit = unit_spawner.hand_area.unit_grid.units[tile]
		if unit:
			hand.append({
				"stats": unit.stats,
				"tile": tile
			})
	return hand

func get_board_state() -> Array:
	# If you have a board area, replace 'board_area' with the correct variable
	var board = []
	for tile in board_area.unit_grid.units:
		var unit = board_area.unit_grid.units[tile]
		if unit:
			board.append({
				"stats": unit.stats,
				"tile": tile
			})
	return board

func _on_fight_button_pressed() -> void:
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	await get_tree().create_timer(0.5).timeout
	GameState.save_state(board_state, hand_state)
	get_tree().change_scene_to_file("res://scenes/combine_board/combineboard.tscn")
