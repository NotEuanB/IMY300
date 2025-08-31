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
		go_to_fight_scene()
	else: 
		$Error.play()

func go_to_fight_scene():
	var board_state = get_board_state()
	var hand_state = get_hand_state()
	await get_tree().create_timer(0.5).timeout
	GameState.save_state(board_state, hand_state)
	
	# Handle tutorial vs main game progression differently
	if GameState.game_mode == GameState.GameMode.TUTORIAL:
		print("Tutorial mode - advancing tutorial step from: ", GameState.current_step)
		GameState.update_step()  # Use tutorial-specific step advancement
		print("Tutorial mode - advanced to step: ", GameState.current_step)
	else:
		GameState.advance()  # Use main game advancement
	
	get_tree().change_scene_to_file("res://scenes/game_flow_manager/GameFlowManager.tscn")


func _on_mouse_entered() -> void:
	$CombineSprite/CombineAnimation.play("Combine_hover")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_hover")

func _on_mouse_exited() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_idle")

var combination_db := {
	"Golem+Rat": preload("res://data/units/combined/rolet.tres"), 
	"Flame Imp+Rat": preload("res://data/units/combined/ashfang_scoundrel.tres"),
	"Flame Imp+Golem": preload("res://data/units/combined/magma_sentinel.tres"),
	"Golem+Moss Troll": preload("res://data/units/combined/bogbound_colossus.tres"),
	"Golem+Spectre": preload("res://data/units/combined/gravestone_warden.tres"),
	"Flame Imp+Moss Troll": preload("res://data/units/combined/blightflame_shaman.tres"),
	"Flame Imp+Spectre": preload("res://data/units/combined/ashwraith.tres"),
	"Moss Troll+Spectre": preload("res://data/units/combined/rotshroud.tres"),
	"Rat+Spectre": preload("res://data/units/combined/shadeblade.tres"),
	"Moss Troll+Rat": preload("res://data/units/combined/rootsnare_bandit.tres")
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
	
	# Create a duplicate of the combined stats to modify
	var buffed_combined_stats = combined_stats.duplicate()
	
	# Initialize base stats for the combined unit FIRST
	if buffed_combined_stats.has_method("initialize_base_stats"):
		buffed_combined_stats.initialize_base_stats()
	
	# Calculate total buffs from both units
	var slot_one_attack_buff = slot_one_unit.stats.attack - slot_one_unit.base_attack
	var slot_one_health_buff = slot_one_unit.stats.health - slot_one_unit.base_health
	var slot_two_attack_buff = slot_two_unit.stats.attack - slot_two_unit.base_attack
	var slot_two_health_buff = slot_two_unit.stats.health - slot_two_unit.base_health
	
	# Apply the combined buffs to the new unit (ONLY ONCE)
	buffed_combined_stats.attack += slot_one_attack_buff + slot_two_attack_buff
	buffed_combined_stats.health += slot_one_health_buff + slot_two_health_buff
	
	print("Unit 1 buffs: +", slot_one_attack_buff, " attack, +", slot_one_health_buff, " health")
	print("Unit 2 buffs: +", slot_two_attack_buff, " attack, +", slot_two_health_buff, " health")
	print("Combined unit final stats: ", buffed_combined_stats.attack, " attack, ", buffed_combined_stats.health, " health")
	
	# Check if this combined unit is already in the pool
	var pool = GameState.get_unit_pool()
	if pool:
		var already_exists = false
		for existing_unit in pool.unit_pool:
			if existing_unit.name == combined_stats.name:
				already_exists = true
				break
		
		if not already_exists:
			pool.add_unit(combined_stats)
			print("Added 1 copy of ", combined_stats.name, " to unit pool!")
		else:
			print("Combined unit ", combined_stats.name, " already exists in pool - not adding duplicate")
	
	# Remove units from slots
	slot_one_area.unit_grid.remove_unit(_get_unit_tile(slot_one_area, slot_one_unit))
	slot_two_area.unit_grid.remove_unit(_get_unit_tile(slot_two_area, slot_two_unit))
	slot_one_unit.queue_free()
	slot_two_unit.queue_free()
	
	# Spawn the buffed combined unit
	unit_spawner.spawn_unit(buffed_combined_stats)
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
	$OverlayLayer/Dimmer.visible = false
	if GameState.game_mode == GameState.GameMode.MAIN_GAME:
		GameState.advance()
		if GameState.is_main_complete():
			call_deferred("change_scene", "res://Scenes/main_menu/main_menu.tscn")
		else:
			call_deferred("change_scene", "res://scenes/game_flow_manager/GameFlowManager.tscn")
	else:
		print("Game mode is TUTORIAL. Returning to tutorial flow.")
