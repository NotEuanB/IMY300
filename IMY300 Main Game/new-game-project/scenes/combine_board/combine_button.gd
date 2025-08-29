extends TextureButton

func _ready() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")

func _on_pressed() -> void:
	var HAND_LIMIT = 6  # Set this to your actual hand size limit

	var slot_one_unit = _get_unit_in_slot(slot_one_area)
	var slot_two_unit = _get_unit_in_slot(slot_two_area)

	# Allow to continue if both slots are empty or only one is filled
	if not slot_one_unit or not slot_two_unit:
		$Button.play()
		await get_tree().create_timer(3).timeout
		go_to_fight_scene()
		return

	# Both slots filled, check if hand is full BEFORE combining
	var hand_count = 0
	for unit in hand_area.unit_grid.units.values():
		if unit:
			hand_count += 1
	if hand_count >= HAND_LIMIT:
		return

	# Try to combine
	var valid = combine_units()
	if valid:
		$Button.play()
		await get_tree().create_timer(3).timeout
		GameState.update_step()
		go_to_fight_scene()
	else: 
		$Error.play()

func go_to_fight_scene():
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	await get_tree().create_timer(0.5).timeout
	GameState.save_state(board_state, hand_state)
	GameState.advance()
	get_tree().change_scene_to_file("res://Scenes/game_flow_manager/GameFlowManager.tscn")


func _on_mouse_entered() -> void:
	$CombineSprite/CombineAnimation.play("Combine_hover")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_hover")

func _on_mouse_exited() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_idle")

var combination_db := {
	"Golem+Rat": preload("res://data/units/rolet.tres"), 
	"Flame Imp+Rat": preload("res://data/units/ashfang_scoundrel.tres"),
	"Flame Imp+Golem": preload("res://data/units/magma_sentinel.tres"),
}

@export var slot_one_area: PlayArea
@export var slot_two_area: PlayArea
@export var hand_area: PlayArea
@export var unit_spawner: UnitSpawner

signal units_combined(combined_unit: Unit)

func combine_units() -> bool:
	var slot_one_unit = _get_unit_in_slot(slot_one_area)
	var slot_two_unit = _get_unit_in_slot(slot_two_area)
	
	var combined_stats = _get_combined_stats(slot_one_unit, slot_two_unit)
	if combined_stats == null:
		return false
	
	# Remove units from slots
	slot_one_area.unit_grid.remove_unit(_get_unit_tile(slot_one_area, slot_one_unit))
	slot_two_area.unit_grid.remove_unit(_get_unit_tile(slot_two_area, slot_two_unit))
	slot_one_unit.queue_free()
	slot_two_unit.queue_free()
	
	unit_spawner.spawn_unit(combined_stats)
	$Combination.play()
	emit_signal("units_combined")
	return true

func _get_unit_in_slot(area: PlayArea) -> Unit:
	for unit in area.unit_grid.units.values():
		if unit:
			return unit
	return null

func _get_unit_tile(area: PlayArea, unit: Unit) -> Vector2i:
	for tile in area.unit_grid.units.keys():
		if area.unit_grid.units[tile] == unit:
			return tile
	return Vector2i(-1, -1)

func _get_combined_stats(slot_one_unit: Unit, slot_two_unit: Unit) -> UnitStats:
	var names = [slot_one_unit.stats.name, slot_two_unit.stats.name]
	names.sort()
	var key = "%s+%s" % [names[0], names[1]]
	var result_stats = combination_db.get(key, null)
	if result_stats == null:
		push_error("No combination found for %s + %s" % [slot_one_unit.stats.name, slot_two_unit.stats.name])
		return null
	return result_stats


func get_hand_state() -> Array:
	var hand = []
	for tile in hand_area.unit_grid.units:
		var unit = hand_area.unit_grid.units[tile]
		if unit:
			hand.append({
				"stats": unit.stats,
				"tile": tile
			})
	return hand

func get_board_state() -> Array:
	var board = []
	if has_node("../PlayArea"):
		var board_area = get_node("../PlayArea") as PlayArea
		for tile in board_area.unit_grid.units:
			var unit = board_area.unit_grid.units[tile]
			if unit:
				board.append({
					"stats": unit.stats,
					"tile": tile
				})
	return board

func _on_reward_ui_closed():
	if not is_inside_tree():
		print("Node is no longer in the scene tree. Cannot change scene.")
		return

	$OverlayLayer/Dimmer.visible = false
	if GameState.game_mode == GameState.GameMode.MAIN_GAME:
		GameState.advance()
		if GameState.is_main_complete():
			call_deferred("change_scene", "res://Scenes/main_menu/main_menu.tscn")
		else:
			call_deferred("change_scene", "res://Scenes/game_flow_manager/GameFlowManager.tscn")
	else:
		print("Game mode is TUTORIAL. Returning to tutorial flow.")
