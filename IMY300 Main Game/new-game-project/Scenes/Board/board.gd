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
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var tutorial_popup = $TutorialPopup
@onready var tutorial_text = $TutorialPopup/TutorialLabel
@onready var tutorial_next = $TutorialPopup/TutorialNext

var paused = false

var hovered_unit: Node = null  # To store the currently hovered unit
var time_hover_started: float = -1.0  # To track the time when hover started (in milliseconds)
var hover_delay: float = 1000.0  # 1 second delay before showing tooltip (in milliseconds)

func _ready() -> void:
	unit_spawner.unit_spawned.connect(unit_mover.setup_unit)
	unit_spawner.unit_spawned.connect(sell_portal.setup_unit)
	shop_container.unit_bought.connect(_on_unit_bought)
	$FightButton.fight_pressed.connect(_on_fight_button_pressed)
	
	# Connect to reroll button for tutorial advancement
	if shop_container.has_node("Top/RerollButton"):
		shop_container.get_node("Top/RerollButton").pressed.connect(_on_reroll_pressed)
	
	# Connect to sell portal for tutorial advancement
	sell_portal.unit_sold.connect(_on_unit_sold)
	
	# Connect to unit mover for tutorial advancement
	unit_mover.unit_moved_to_board.connect(_on_unit_moved_to_board)

	# Restore the saved state
	var states = GameState.load_state()
	var board_units = states["board_units"]
	var hand_units = states["hand_units"]
	_spawn_units(board_units, board_area)
	_spawn_units(hand_units, hand_area)

	print("=== BOARD READY DEBUG ===")
	print("GameState.game_mode: ", GameState.game_mode)
	print("GameState.current_step: ", GameState.current_step)
	print("=== END BOARD READY DEBUG ===")
	
	# Use call_deferred to ensure shop_container is fully ready
	call_deferred("_show_step_popup")

func _on_unit_bought(unit_stats: UnitStats) -> void:
	unit_spawner.spawn_unit(unit_stats)
	
	# Auto-advance tutorial when buying in tutorial mode
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		# Only advance if we're in the specific step for buying (don't advance past 1_9)
		if GameState.current_step == GameState.GameStep.STEP_1_6:
			print("Unit bought - advancing tutorial from STEP_1_6")
			GameState.update_step()
			call_deferred("_show_step_popup")

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
			# Only save units that aren't currently being dragged
			var is_dragging = false
			if unit.has_node("DragAndDrop"):
				is_dragging = unit.get_node("DragAndDrop").dragging
			
			if not is_dragging:
				hand.append({
					"stats": unit.stats,
					"tile": tile
				})
			else:
				print("Skipping dragged unit in hand: ", unit.stats.name)
	return hand

func get_board_state() -> Array:
	# If you have a board area, replace 'board_area' with the correct variable
	var board = []
	for tile in board_area.unit_grid.units:
		var unit = board_area.unit_grid.units[tile]
		if unit:
			# Only save units that aren't currently being dragged
			var is_dragging = false
			if unit.has_node("DragAndDrop"):
				is_dragging = unit.get_node("DragAndDrop").dragging
			
			if not is_dragging:
				board.append({
					"stats": unit.stats,
					"tile": tile
				})
			else:
				print("Skipping dragged unit on board: ", unit.stats.name)
	return board

func _on_fight_button_pressed() -> void:
	# Cancel any active dragging before scene change
	_cancel_all_dragging()
	
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	await get_tree().create_timer(0.5).timeout
	
	# Handle tutorial vs main game progression differently
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		# Special case: In STEP_1_9, the Fight button should advance the tutorial
		if GameState.current_step == GameState.GameStep.STEP_1_9:
			print("Tutorial mode STEP_1_9 - Fight button pressed, advancing tutorial")
			GameState.update_step()  # Advance from STEP_1_9 to next step
		else:
			print("Tutorial mode - NOT advancing step (already advanced by Next button)")
			# Don't advance step in tutorial mode for other steps - Next button handles that
	else:
		print("Main game mode - advancing main game step")
		GameState.advance()  # Use main game advancement
	
	GameState.save_state(board_state, hand_state)
	get_tree().change_scene_to_file("res://scenes/game_flow_manager/GameFlowManager.tscn")

func _spawn_units(units_data: Array, play_area: PlayArea) -> void:
	for unit_data in units_data:
		var stats = unit_data["stats"]
		var tile = unit_data["tile"]
		var unit_scene = stats.unit_scene if stats.unit_scene else preload("res://scenes/unit/unit.tscn")
		var unit = unit_scene.instantiate()
		play_area.unit_grid.add_child(unit)
		play_area.unit_grid.add_unit(tile, unit)
		unit.global_position = play_area.get_global_from_tile(tile)
		unit.stats = stats.duplicate()
		unit_mover.setup_unit(unit)
		sell_portal.setup_unit(unit)  # ADD THIS LINE

func _show_step_popup() -> void:
	print("=== BOARD TUTORIAL DEBUG ===")
	print("Game mode: ", GameState.game_mode)
	print("Current step enum value: ", GameState.current_step)
	
	# Only show tutorial popups if in Tutorial Mode
	if GameState.game_mode != GameState.GameMode.TUTORIAL:
		print("Not in tutorial mode - hiding popup")
		tutorial_popup.visible = false
		_enable_all_interactions()  # Enable everything in main game
		return
	
	# If we're in tutorial mode but at STEP_1, advance to STEP_1_1
	if GameState.current_step == GameState.GameStep.STEP_1:
		print("At STEP_1, advancing to STEP_1_1")
		GameState.current_step = GameState.GameStep.STEP_1_1
	
	print("In tutorial mode - checking step match...")
	
	# Show tutorial popups based on the current step
	match GameState.current_step:
		GameState.GameStep.STEP_1_1:
			print("✅ MATCHED STEP_1_1 - Showing popup")
			tutorial_text.text = "This is the shop screen, where you can buy units and manipulate your board area to create effective battle teams!"
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 500
			tutorial_popup.visible = true
			tutorial_next.visible = true  # Show next button for informational step
			_set_tutorial_interactions(false, false, false, false)  # Disable everything
			
		GameState.GameStep.STEP_1_2:
			print("✅ MATCHED STEP_1_2 - Showing popup")
			tutorial_text.text = "These are the units that are currently available in the shop."
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 800
			$HighlightBoard.visible = true
			$HighlightBoard/HighlightAnimation.play("Board")
			tutorial_popup.visible = true
			tutorial_next.visible = true  # Show next button for informational step
			_set_tutorial_interactions(false, false, false, false)  # Still disabled
			
		GameState.GameStep.STEP_1_3:
			$HighlightBoard.visible = false
			tutorial_text.text = "This is the unit card itself."
			tutorial_popup.position.x = 800
			tutorial_popup.position.y = 400
			$HighlightUnit.visible = true
			$HighlightUnit/HighlightAnimation.play("Unit")
			tutorial_popup.visible = true
			tutorial_next.visible = true  # Show next button for informational step
			_set_tutorial_interactions(false, false, false, false)
			
		GameState.GameStep.STEP_1_4:
			$HighlightUnit.visible = false
			tutorial_text.text = "You can see your available gold here."
			tutorial_popup.position.x = 1150
			tutorial_popup.position.y = 300
			$HighlightGold.visible = true
			$HighlightGold/HighlightAnimation.play("Gold")
			tutorial_popup.visible = true
			tutorial_next.visible = true  # Show next button for informational step
			_set_tutorial_interactions(false, false, false, false)
			
		GameState.GameStep.STEP_1_5:
			$HighlightGold.visible = false
			tutorial_text.text = "Try using the reroll button!"
			tutorial_popup.position.x = 800
			tutorial_popup.position.y = 300
			$HighlightReroll.visible = true
			$HighlightReroll/HighlightAnimation.play("Reroll")
			tutorial_popup.visible = true
			tutorial_next.visible = false  # Hide next button - user must reroll
			_set_tutorial_interactions(false, false, true, false)  # Enable reroll only
			
		GameState.GameStep.STEP_1_6:
			$HighlightReroll.visible = false
			tutorial_text.text = "Buy a unit by clicking on it!"
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 250
			tutorial_popup.visible = true
			tutorial_next.visible = false  # Hide next button - user must buy units
			_set_tutorial_interactions(true, false, true, false)  # Enable shop buying + reroll
			
		GameState.GameStep.STEP_1_7:
			tutorial_text.text = "Move your unit from the hand to the board space above."
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 600
			$HighlightBoard.position.y = 1040
			$HighlightBoard.visible = true
			$HighlightBoard/HighlightAnimation.play("Board")
			tutorial_popup.visible = true
			tutorial_next.visible = false  # Hide next button - user must move units
			_set_tutorial_interactions(false, true, false, false)  # Enable unit moving only
			
		GameState.GameStep.STEP_1_8:
			tutorial_text.text = "Try selling your unit by dragging to the top of the screen."
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 500
			$HighlightBoard.position.y = 700
			$HighlightBoard.visible = true
			$HighlightBoard/HighlightAnimation.play("Board")
			tutorial_popup.visible = true
			tutorial_next.visible = false  # Hide next button - user must sell unit
			_set_tutorial_interactions(false, true, false, true)  # Enable moving + selling
			
		GameState.GameStep.STEP_1_9:
			$HighlightBoard.visible = false
			tutorial_text.text = "Buy some more units and place them on the board like you want to place, then, once you are happy, proceed to the next stage by clicking the Fight button!"
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 500
			tutorial_popup.visible = true
			tutorial_next.visible = false  # Hide next button - user must click Fight button
			_set_tutorial_interactions(true, true, true, true)  # Enable everything
			
		GameState.GameStep.STEP_2, GameState.GameStep.STEP_2_1, GameState.GameStep.FIGHT:
			# Tutorial has moved beyond shop steps - hide popup and enable everything
			print("✅ TUTORIAL PAST SHOP - Hiding popup and enabling all interactions")
			tutorial_popup.visible = false
			_enable_all_interactions()  # Enable everything including fight button
			
		_:
			print("❌ NO MATCH - Current step: ", GameState.current_step)
			tutorial_popup.visible = false
			_enable_all_interactions()  # Enable everything if no match

func _set_tutorial_interactions(shopping: bool, moving: bool, rerolling: bool, selling: bool) -> void:
	# Control shop buying
	shop_container.set_purchasing_enabled(shopping)
	
	# Control unit moving
	unit_mover.set_enabled(moving)
	_set_all_drag_and_drop_enabled(moving)
	
	# Control reroll button
	if shop_container.has_node("Top/RerollButton"):
		shop_container.get_node("Top/RerollButton").disabled = !rerolling
	
	# Control selling
	sell_portal.set_enabled(selling)
	
	# Control fight button - enable when tutorial reaches final shop steps or moves beyond shop
	var fight_enabled = (GameState.game_mode != GameState.GameMode.TUTORIAL) or (GameState.current_step == GameState.GameStep.STEP_1_9) or (GameState.current_step == GameState.GameStep.STEP_2) or (GameState.current_step == GameState.GameStep.STEP_2_1) or (GameState.current_step == GameState.GameStep.FIGHT)
	
	if has_node("FightButton"):
		$FightButton.disabled = !fight_enabled
		print("Fight button disabled state: ", $FightButton.disabled, " (current_step: ", GameState.current_step, ", fight_enabled: ", fight_enabled, ")")
	
	print("Tutorial interactions - Shopping:", shopping, " Moving:", moving, " Rerolling:", rerolling, " Selling:", selling, " Fight:", fight_enabled)

func _enable_all_interactions() -> void:
	_set_tutorial_interactions(true, true, true, true)

func _set_all_drag_and_drop_enabled(enabled: bool) -> void:
	print("Setting drag and drop enabled: ", enabled)
	var hand_count = 0
	var board_count = 0
	
	# Enable/disable drag and drop for units in hand
	for unit in hand_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled
			hand_count += 1
	
	# Enable/disable drag and drop for units on board
	for unit in board_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled
			board_count += 1
	
	print("Updated drag and drop for ", hand_count, " hand units and ", board_count, " board units")

func _on_next_step_pressed() -> void:
	print("Next button pressed - current step: ", GameState.current_step)
	GameState.update_step()
	print("After update - new step: ", GameState.current_step)
	_show_step_popup()

func _on_reroll_pressed() -> void:
	# Auto-advance tutorial when rerolling in tutorial mode
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		# Only advance if we're in the specific step for rerolling (don't advance past 1_9)
		if GameState.current_step == GameState.GameStep.STEP_1_5:
			print("Reroll pressed - advancing tutorial from STEP_1_5")
			GameState.update_step()
			call_deferred("_show_step_popup")

func _on_unit_sold(_unit: Unit) -> void:
	# Auto-advance tutorial when selling in tutorial mode
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		# Check if we're in a step where selling should advance the tutorial
		if GameState.current_step == GameState.GameStep.STEP_1_8:
			print("Unit sold - advancing tutorial from STEP_1_8")
			GameState.update_step()
			call_deferred("_show_step_popup")

func _on_unit_moved_to_board(_unit: Unit) -> void:
	# Auto-advance tutorial when moving unit to board in tutorial mode
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		# Check if we're in a step where moving to board should advance the tutorial
		if GameState.current_step == GameState.GameStep.STEP_1_7:
			print("Unit moved to board - advancing tutorial from STEP_1_7")
			GameState.update_step()
			call_deferred("_show_step_popup")

func _cancel_all_dragging() -> void:
	# Cancel dragging for all units in hand
	for unit in hand_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			var drag_drop = unit.get_node("DragAndDrop")
			if drag_drop.dragging:
				print("Cancelling drag for hand unit: ", unit.stats.name)
				drag_drop._cancel_dragging()
	
	# Cancel dragging for all units on board
	for unit in board_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			var drag_drop = unit.get_node("DragAndDrop")
			if drag_drop.dragging:
				print("Cancelling drag for board unit: ", unit.stats.name)
				drag_drop._cancel_dragging()
