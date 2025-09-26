extends Node2D

@onready var unit_mover: UnitMover = $UnitMover
@onready var unit_spawner: UnitSpawner = $UnitSpawner
@onready var board_area: PlayArea = $PlayArea
@onready var hand_area: PlayArea = $HandArea
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var tutorial_popup = $TutorialPopup
@onready var tutorial_text = $TutorialPopup/TutorialLabel

var paused = false

func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	
	paused = !paused

func _ready() -> void:
	# Ensure family display is available
	GameState.ensure_family_display_in_scene()
	
	if GameState.game_mode == GameState.GameMode.MAIN_GAME:
		# Main game flow
		_update_ui_for_main_game()
		var states = GameState.load_state()
		var board_units = states["board_units"]
		var hand_units = states["hand_units"]
		_spawn_units(board_units, $PlayArea)
		_spawn_units(hand_units, $HandArea)
		return

	# Tutorial flow
	$FlowMenuAnimation/FlowMenuAnimation.play("Flowmenu_idle")
	_update_ui()
	var tut_states = GameState.load_state()
	var tut_board_units = tut_states["board_units"]
	var tut_hand_units = tut_states["hand_units"]
	_spawn_units(tut_board_units, $PlayArea)
	_spawn_units(tut_hand_units, $HandArea)
	_show_tutorial_popup()

func _show_tutorial_popup() -> void:
	match GameState.current_step:
		GameState.GameStep.STEP_1: 
			tutorial_text.text = "Welcome to the game! Here are your options:\n\n- Shop: Buy units.\n- Combine: Combine units.\n\nPress the Shop button to begin."
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 600
			$ShopButton.disabled = false
			$CombineButton.disabled = true
			$FightButton.disabled = true
		GameState.GameStep.STEP_2:
			$ShopButton.disabled = true
			$CombineButton.disabled = false
			$FightButton.disabled = true
			tutorial_text.text = "Now that you have seen and understand the shop, let us go to the combination of units. \n\n Click on the combine button to proceed."
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 600
		GameState.GameStep.FIGHT:
			$ShopButton.visible = false
			$CombineButton.visible = false
			$FightButton.visible = true
			tutorial_text.text = "In this screen, you can still change around the units you have on the board. Drag the new combined unit from your hand to the battlefield.\n\nWhen seeing this screen for the 3rd time after starting the game, or after a fight, your only option will be to take the fight.\n\n Click on the button to proceed."
			tutorial_popup.position.x = 900
			tutorial_popup.position.y = 600

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pauseMenu()

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
	
	# Apply family bonuses after spawning units
	_apply_family_bonuses_to_board()

func _apply_family_bonuses_to_board():
	"""Apply family bonuses to all units currently on the board"""
	var board_units = []
	
	# Collect all living units on the board
	for unit in board_area.unit_grid.units.values():
		if unit and unit.stats and unit.stats.health > 0:
			board_units.append(unit)
	
	# Apply family bonuses through GameState
	GameState.apply_family_bonuses_to_board(board_units)
	
	# Refresh the global family display
	GameState.refresh_global_family_display()
	
	print("GameFlowManager: Applied family bonuses to ", board_units.size(), " units")

func _update_ui() -> void:
	# Hide all buttons initially
	$ShopButton.visible = false
	$CombineButton.visible = false
	$FightButton.visible = false

	# Show buttons based on the current step
	match GameState.current_step:
		GameState.GameStep.STEP_1, GameState.GameStep.STEP_2:
			$ShopButton.visible = true
			$CombineButton.visible = true
		GameState.GameStep.FIGHT:
			$ShopButton.visible = false
			$CombineButton.visible = false
			$FightButton.visible = true

func _update_ui_for_main_game() -> void:
	# Show buttons based on the current step in the main game
	$ShopButton.visible = GameState.main_step == GameState.MainStep.SHOP
	$CombineButton.visible = GameState.main_step == GameState.MainStep.COMBINE
	$FightButton.visible = GameState.main_step == GameState.MainStep.FIGHT

func _load_scene(scene_path: String) -> void:
	var result = get_tree().change_scene_to_file(scene_path)
	_update_ui()

func get_hand_state() -> Array:
	var hand = []
	for tile in unit_spawner.hand_area.unit_grid.units:
		var unit = unit_spawner.hand_area.unit_grid.units[tile]
		if unit:
			var unit_drag_component = unit.get_node_or_null("UnitMover")
			if unit_drag_component and unit_drag_component.is_dragging:
				continue
			
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
			var unit_drag_component = unit.get_node_or_null("UnitMover")
			if unit_drag_component and unit_drag_component.is_dragging:
				continue
			
			board.append({
				"stats": unit.stats,
				"tile": tile
			})
	return board


func _on_fight_button_pressed() -> void:
	_cancel_all_dragging()
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	GameState.save_state(board_state, hand_state)
	
	# If in tutorial mode, advance the step
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		GameState.advance()  # This should advance to next tutorial step	
	_load_scene("res://scenes/forest_board/forestboard.tscn")

func _on_combine_button_pressed() -> void:
	# Cancel any active dragging before saving state
	_cancel_all_dragging()
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	GameState.save_state(board_state, hand_state)
	
	# If in tutorial mode, advance the step
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		GameState.advance()  # This should advance to next tutorial step
	
	_load_scene("res://scenes/combine_board/combineboard.tscn")

func _on_shop_button_pressed() -> void:
	# Cancel any active dragging before saving state
	_cancel_all_dragging()
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	GameState.save_state(board_state, hand_state)
	
	# If in tutorial mode, advance the step
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		GameState.advance()  # This should go from STEP_1 (0) to STEP_1_1 (3)
	
	_load_scene("res://scenes/board/board.tscn")

func _cancel_all_dragging():
	# Cancel any active dragging in any unit mover components
	var drag_components = get_tree().get_nodes_in_group("drag_components")
	for component in drag_components:
		if component and component.has_method("cancel_drag"):
			component.cancel_drag()
	
	# Cancel any active target selection (like Shadeblade ability)
	if UnitMover.is_selecting_target:
		UnitMover.is_selecting_target = false
		UnitMover.selecting_unit = null
		
		# Reset all unit selectable states
		var all_units = get_tree().get_nodes_in_group("units")
		for unit in all_units:
			if is_instance_valid(unit) and unit.has_method("set_selectable"):
				unit.set_selectable(false)
