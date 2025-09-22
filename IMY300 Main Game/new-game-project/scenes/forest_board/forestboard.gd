class_name ForestBoard
extends Node2D

@onready var unit_mover: UnitMover = $UnitMover
@onready var player_area: PlayArea = $PlayArea
@onready var hand_area: PlayArea = $HandArea
@onready var enemy_area: PlayArea = $EnemyArea
@export var player_stats: Resource
var enemy_stats: EnemyStats
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var tutorial_popup = $TutorialPopup
@onready var tutorial_text = $TutorialPopup/TutorialText
@onready var camera_shake: Node = $Camera2D
@onready var enemy_avatar_display: Sprite2D = $Visuals/Goblin
var paused = false

# Track original unit positions and stats for respawning
var original_board_units = []
var original_hand_units = []
# Track units that died during combat with their final stats
var dead_units_final_stats = {}

# Attack/combat timing (adjust in Inspector)
@export var combat_start_delay: float = 3
@export var attack_move_duration: float = 0.35
@export var attack_return_duration: float = 0.35
@export var attack_cooldown: float = 0.5

# Boss intro settings (assign in Inspector; DIY-friendly)
@export var boss_intro_enabled: bool = true
@export var boss_intro_fade_in: float = 0.5
@export var boss_intro_hold: float = 3
@export var boss_intro_fade_out: float = 0.5
@export var boss_music_fade_out: float = 0.25
@export var boss_music_fade_in: float = 0.4
@export var boss_intro_image: Texture2D
@export var boss_music_stream: AudioStream

const DEFAULT_BOSS_INTRO_IMAGE_PATH := "res://assets/backgrounds/Ashfang_Boss_Intro.png"
const DEFAULT_BOSS_MUSIC_PATHS := [
	"res://assets/sfx/music/boss_fight.ogg",
	"res://assets/sfx/music/boss_fight.wav",
	"res://assets/sfx/boss_fight.ogg",
	"res://assets/sfx/boss_fight.wav"
]

@onready var intro_layer: CanvasLayer = $IntroLayer if has_node("IntroLayer") else null
@onready var boss_intro: Control = $IntroLayer/BossIntro if has_node("IntroLayer/BossIntro") else null
@onready var intro_texrect: TextureRect = $IntroLayer/BossIntro/TextureRect if has_node("IntroLayer/BossIntro/TextureRect") else null
@onready var music: AudioStreamPlayer2D = $Music if has_node("Music") else null


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

func _ready() -> void:
	randomize()
	
	# Get enemies for the current round FIRST
	enemy_stats = GameState.get_enemies_for_round(GameState.main_round)
	if not enemy_stats:
		print("ERROR: No enemy stats found for round ", GameState.main_round)
		# Fallback to a default enemy if needed
		enemy_stats = preload("res://data/enemy/goblin.tres")
	
	print("Fighting enemies for round ", GameState.main_round, ": ", enemy_stats.resource_path)
	
	# Set the enemy avatar (skin) based on the current enemy
	_set_enemy_avatar()
	
	# Set the background based on the current round
	_set_background_for_round()
	
	var states = GameState.load_state()
	var board_units = states["board_units"]
	var hand_units = states["hand_units"]
	_spawn_units(board_units, player_area)
	_spawn_units(hand_units, hand_area)
	_spawn_enemy_units()
	_set_all_drag_and_drop_enabled(false)
	_set_all_units_enabled(false) 
	unit_mover.set_enabled(false)
	# Show boss intro on Round 4 (or toggle with boss_intro_enabled), else keep normal delay
	if GameState.main_round == 4 and boss_intro_enabled:
		await show_boss_intro_then_start()
	else:
		await get_tree().create_timer(combat_start_delay).timeout
		start_combat()

func show_boss_intro_then_start() -> void:
	$Ambience.stop()
	# Safeguards: require overlay nodes; if missing, fall back
	if boss_intro == null or intro_texrect == null:
		await get_tree().create_timer(combat_start_delay).timeout
		start_combat()
		return

	# Fallback: allow unassigned assets by loading defaults
	if boss_intro_image == null:
		var tex: Texture2D = load(DEFAULT_BOSS_INTRO_IMAGE_PATH)
		if tex:
			boss_intro_image = tex
	if boss_music_stream == null:
		for p in DEFAULT_BOSS_MUSIC_PATHS:
			var s: AudioStream = load(p)
			if s:
				boss_music_stream = s
				break

	# If we still don't have an image, skip the intro gracefully
	if boss_intro_image == null:
		await get_tree().create_timer(combat_start_delay).timeout
		start_combat()
		return

	print("Boss intro: round=", GameState.main_round, ", image=", boss_intro_image != null, ", music=", boss_music_stream != null)

	# Set image and fade in
	intro_texrect.texture = boss_intro_image
	boss_intro.visible = true
	boss_intro.modulate.a = 0.0
	var t_in = create_tween()
	t_in.tween_property(boss_intro, "modulate:a", 1.0, boss_intro_fade_in)
	await t_in.finished

	# Music swap with fade
	if music:
		if music.playing:
			var tf = create_tween()
			tf.tween_property(music, "volume_db", -24.0, boss_music_fade_out)
			await tf.finished
		music.stop()
		if boss_music_stream:
			music.stream = boss_music_stream
		music.volume_db = -24.0
		music.play()
		create_tween().tween_property(music, "volume_db", 0.0, boss_music_fade_in)

	# Hold, then fade out and start combat
	await get_tree().create_timer(boss_intro_hold).timeout
	var t_out = create_tween()
	t_out.tween_property(boss_intro, "modulate:a", 0.0, boss_intro_fade_out)
	await t_out.finished
	boss_intro.visible = false
	start_combat()

func _set_enemy_avatar() -> void:
	if enemy_stats and enemy_stats.skin and enemy_avatar_display:
		enemy_avatar_display.texture = enemy_stats.skin
		print("Set enemy avatar (skin) for: ", enemy_stats.resource_path)
	else:
		print("No enemy skin found or avatar display element missing")

func _set_background_for_round() -> void:
	# Assuming you have a background node in your scene
	var background_node = $Visuals/Background  # Adjust the path to your background node
	
	match GameState.main_round:
		1:
			background_node.texture = preload("res://assets/backgrounds/Forest_board.png")
			print("Set background for Round 1")
		2:
			background_node.texture = preload("res://assets/backgrounds/Grave_Hollow.png")
			print("Set background for Round 2")
		3:
			background_node.texture = preload("res://assets/backgrounds/Scorched_Gate.png")
			print("Set background for Round 3")
		4:
			background_node.texture = preload("res://assets/backgrounds/Ashfangs_Keep.png")
			print("Set background for Round 4")
		_:
			# Default background
			background_node.texture = preload("res://assets/backgrounds/Forest_board.png")
			print("Set default background")

func _show_tutorial_popup() -> void:
	match GameState.current_step:
		GameState.GameStep.FIGHT: 
			tutorial_text.text = "As you saw, the combat happens automatically.\nThe rewards are worked out based on the number of enemies killed, as well as certain team compositions in the future.\n\nExperiment around to see what builds you like and get stronger!"
			tutorial_popup.position.x = 960
			tutorial_popup.position.y = 500
			tutorial_popup.z_index = 100
			tutorial_popup.visible = true

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
		
		# Initialize max_health_reached to current health
		unit.max_health_reached = unit.stats.health

func _spawn_enemy_units() -> void:
	for i in range(enemy_stats.units.size()):
		var unit_scene = enemy_stats.units[i]
		var tile = Vector2i(i, 0)
		var unit = unit_scene.instantiate()
		enemy_area.unit_grid.add_child(unit)
		enemy_area.unit_grid.add_unit(tile, unit)
		unit.global_position = enemy_area.get_global_from_tile(tile)
		if i < enemy_stats.unit_stats.size() and enemy_stats.unit_stats[i]:
			unit.stats = enemy_stats.unit_stats[i].duplicate()
		else:
			unit.stats = null

func get_living_unit_count(unit_grid) -> int:
	var count = 0
	for unit in unit_grid.units.values():
		if unit and unit.stats and unit.stats.health > 0:
			count += 1
	return count

func show_reward_ui(title_text: String, description_text: String) -> void:
	$OverlayLayer/Dimmer.visible = true  # Show the dimmer
	var reward_ui_scene = preload("res://scenes/rewards/reward_ui.tscn")
	var reward_ui = reward_ui_scene.instantiate()
	$OverlayLayer.add_child(reward_ui)
	reward_ui.get_node("Title").text = title_text
	reward_ui.get_node("Description").text = description_text

	# Optionally, hide the dimmer when the reward UI is closed
	reward_ui.connect("tree_exited", Callable(self, "_on_reward_ui_closed"))

func _on_reward_ui_closed():
	print("Reward UI closed. Game mode:", GameState.game_mode, ", Main step:", GameState.main_step, ", Round:", GameState.main_round)

	# Ensure the node is still in the scene tree
	if not is_inside_tree():
		print("Node is no longer in the scene tree. Cannot change scene.")
		return

	$OverlayLayer/Dimmer.visible = false
	_show_tutorial_popup()

	# Handle scene transition based on game mode
	if GameState.game_mode == GameState.GameMode.MAIN_GAME:
		GameState.advance()
		if GameState.is_main_complete():
			call_deferred("change_scene", "res://scenes/main_menu/main_menu.tscn")
		else:
			call_deferred("change_scene", "res://scenes/game_flow_manager/GameFlowManager.tscn")

func change_scene(scene_path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Cannot change scene. get_tree() is null.")

func start_combat() -> void:
	# Store original unit states at combat start (before any deaths)
	_store_original_unit_states()
	
	# Reset resurrection flag for new combat
	_resurrection_used_this_combat = false
	
	# Trigger combat start abilities for all player units
	for unit in player_area.unit_grid.units.values():
		if unit and unit.stats and unit.stats.health > 0:
			if unit.has_method("on_combat_start"):
				unit.on_combat_start(enemy_area)
	
	var initial_enemy_count = get_living_unit_count(enemy_area.unit_grid)
	
	while get_living_unit_count(player_area.unit_grid) > 0 and get_living_unit_count(enemy_area.unit_grid) > 0:		
		await _combat_round()

	# Calculate enemies killed
	var final_enemy_count = get_living_unit_count(enemy_area.unit_grid)
	var enemies_killed = initial_enemy_count - final_enemy_count
	
	# Award gold for enemies killed
	var gold_earned = enemies_killed
	player_stats.gold += gold_earned
	player_stats.changed.emit()
	
	# Save the updated unit states (including any Soul Drain bonuses)
	_save_combat_results()
	
	# Determine the outcome
	var player_units_alive = get_living_unit_count(player_area.unit_grid)
	var enemy_units_alive = get_living_unit_count(enemy_area.unit_grid)
	
	if player_units_alive == 0 and enemy_units_alive == 0:
		# Draw - both sides wiped out
		$Lose.play()  # or create a separate draw sound
		show_reward_ui("Draw", "Both armies were wiped out!\n+" + str(gold_earned) + " gold for killing " + str(enemies_killed) + " enemies!")
		
	elif player_units_alive == 0:
		# Player loses - lose health equal to remaining enemies
		var health_lost = enemy_units_alive
		player_stats.health -= health_lost
		$Visuals/HealthDisplay/Health.text = str(player_stats.health)
		$Lose.play()
		
		if enemies_killed > 0:
			show_reward_ui("You Lose", "You lost " + str(health_lost) + " HP!\n(" + str(enemy_units_alive) + " enemies remain)\n+" + str(gold_earned) + " gold for killing " + str(enemies_killed) + " enemies!")
		else:
			show_reward_ui("You Lose", "You lost " + str(health_lost) + " HP! (" + str(enemy_units_alive) + " enemies remain)")
			
	elif enemy_units_alive == 0:
		# Player wins - get bonus gold plus kill gold
		$Win.play()
		player_stats.gold += 3
		player_stats.changed.emit()
		show_reward_ui("You Win", "Victory!\n+3 Gold \n+" + str(gold_earned) + " gold for killing " + str(enemies_killed) + " enemies!")

func _player_turn() -> void:
	var living_player_tiles = []
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_player_tiles.append(tile)
	if living_player_tiles.size() == 0:
		return

	var player_tile = living_player_tiles[randi() % living_player_tiles.size()]
	var player_unit = player_area.unit_grid.units[player_tile]

	# Get all living enemy tiles
	var living_enemy_tiles = []
	for tile in enemy_area.unit_grid.units.keys():
		var unit = enemy_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_enemy_tiles.append(tile)
	if living_enemy_tiles.size() == 0:
		return

	var enemy_tile = living_enemy_tiles[randi() % living_enemy_tiles.size()]
	var enemy_unit = enemy_area.unit_grid.units[enemy_tile]

	_attack(player_unit, enemy_unit)

func _enemy_turn() -> void:
	# Get all living enemy tiles
	var living_enemy_tiles = []
	for tile in enemy_area.unit_grid.units.keys():
		var unit = enemy_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_enemy_tiles.append(tile)
	if living_enemy_tiles.size() == 0:
		return

	# Pick a random living enemy
	var enemy_tile = living_enemy_tiles[randi() % living_enemy_tiles.size()]
	var enemy_unit = enemy_area.unit_grid.units[enemy_tile]

	# Get all living player tiles
	var living_player_tiles = []
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			living_player_tiles.append(tile)
	if living_player_tiles.size() == 0:
		return  # No players left

	# Pick a random living player
	var player_tile = living_player_tiles[randi() % living_player_tiles.size()]
	var player_unit = player_area.unit_grid.units[player_tile]

	# Perform attack
	_attack(enemy_unit, player_unit)

func _attack(attacker, defender) -> void:
	if attacker == null or defender == null:
		return
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var original_pos = attacker.global_position
	var target_pos = defender.global_position
	var original_z = attacker.z_index

	# Bring attacker to front
	attacker.z_index = defender.z_index + 1

	# Animate attacker moving to defender
	var tween = create_tween()
	tween.tween_property(attacker, "global_position", target_pos, attack_move_duration)
	await tween.finished

	# Both units deal damage to each other
	if camera_shake and camera_shake.has_method("shake"):
		camera_shake.shake(10.0, 0.2, 8)
	defender.stats.health -= attacker.stats.attack
	attacker.stats.health -= defender.stats.attack
	_update_health_display(defender)
	_update_health_display(attacker)
	print("%s attacks %s for %d damage! %s counterattacks for %d damage!" % [
		attacker.stats.name, defender.stats.name, attacker.stats.attack,
		defender.stats.name, defender.stats.attack
	])

	# Animate attacker moving back to original position
	var tween_back = create_tween()
	tween_back.tween_property(attacker, "global_position", original_pos, attack_return_duration)
	await tween_back.finished

	# Restore original z_index
	attacker.z_index = original_z

	# Handle unit deaths using the helper function
	if defender.stats.health <= 0:
		_handle_unit_death(defender, attacker)
	if attacker.stats.health <= 0:
		_handle_unit_death(attacker, defender)
	$Attack.play()

# Helper function to handle unit death properly
func _handle_unit_death(dead_unit: Unit, killer_unit: Unit = null) -> void:
	if not is_instance_valid(dead_unit) or dead_unit.stats.health > 0:
		return
	
	# Check for Shadow Resurrection FIRST (before removing from grid)
	var was_resurrected = false
	if dead_unit in player_area.unit_grid.units.values():
		was_resurrected = _try_shadow_resurrection(dead_unit)
	
	# If resurrected, don't process death
	if was_resurrected:
		print("Unit was resurrected - skipping death processing")
		return
	
	# Save final stats of player units that die (for proper respawning with bonuses)
	if dead_unit in player_area.unit_grid.units.values():
		var tile = player_area.unit_grid.units.keys()[player_area.unit_grid.units.values().find(dead_unit)]
		dead_units_final_stats[tile] = {
			"stats": dead_unit.stats.duplicate(),
			"max_health_reached": dead_unit.max_health_reached
		}
		print("Saved final stats for dead unit ", dead_unit.stats.name, " at tile ", tile)
	
	# Trigger on_kill for the killer if it exists and survived
	if killer_unit and is_instance_valid(killer_unit) and killer_unit.stats.health > 0:
		killer_unit.on_kill(dead_unit)
	
	# Remove unit from the appropriate grid
	if dead_unit in player_area.unit_grid.units.values():
		var tile = player_area.unit_grid.units.keys()[player_area.unit_grid.units.values().find(dead_unit)]
		player_area.unit_grid.remove_unit(tile)
	elif dead_unit in enemy_area.unit_grid.units.values():
		var tile = enemy_area.unit_grid.units.keys()[enemy_area.unit_grid.units.values().find(dead_unit)]
		enemy_area.unit_grid.remove_unit(tile)
	
	# Queue the unit for deletion
	dead_unit.queue_free()
	print(dead_unit.stats.name, " was removed from the battlefield")

func _update_health_display(unit):
	# Update max_health_reached if current health is higher (for healing)
	if unit.stats.health > unit.max_health_reached:
		unit.max_health_reached = unit.stats.health
	
	# Use the unit's own display update functions instead of directly setting text
	if unit.has_method("update_stat_display_health") and unit.unit_hp:
		unit.update_stat_display_health(unit.unit_hp, unit.stats.health, unit.base_health, unit.max_health_reached)
	
	# Also update attack display in case it changed
	if unit.has_method("update_stat_display_attack") and unit.unit_atk:
		unit.update_stat_display_attack(unit.unit_atk, unit.stats.attack, unit.base_attack)

func _set_all_units_enabled(enabled: bool) -> void:
	for unit in player_area.unit_grid.units.values():
		if unit and unit.has_method("set_enabled"):
			unit.set_enabled(enabled)
	for unit in hand_area.unit_grid.units.values():
		if unit and unit.has_method("set_enabled"):
			unit.set_enabled(enabled)
	for unit in enemy_area.unit_grid.units.values():
		if unit and unit.has_method("set_enabled"):
			unit.set_enabled(enabled)

func _set_all_drag_and_drop_enabled(enabled: bool) -> void:
	for unit in player_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled
	for unit in hand_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled
	for unit in enemy_area.unit_grid.units.values():
		if unit and unit.has_node("DragAndDrop"):
			unit.get_node("DragAndDrop").enabled = enabled

func _combat_round() -> void:
	var player_tiles := []
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			player_tiles.append(tile)
	player_tiles.sort_custom(func(a, b): return a.y < b.y if a.x == b.x else a.x < b.x)

	var enemy_tiles := []
	for tile in enemy_area.unit_grid.units.keys():
		var unit = enemy_area.unit_grid.units[tile]
		if unit and unit.stats and unit.stats.health > 0:
			enemy_tiles.append(tile)
	enemy_tiles.sort_custom(func(a, b): return a.y < b.y if a.x == b.x else a.x < b.x)

	var i = 0
	var j = 0
	while i < player_tiles.size() or j < enemy_tiles.size():
		# Player attacks
		if i < player_tiles.size() and enemy_tiles.size() > 0:
			var player_unit = player_area.unit_grid.units[player_tiles[i]]
			# Refresh living enemy tiles
			var living_enemy_tiles = []
			for tile in enemy_area.unit_grid.units.keys():
				var unit = enemy_area.unit_grid.units[tile]
				if unit and unit.stats and unit.stats.health > 0:
					living_enemy_tiles.append(tile)
			if living_enemy_tiles.size() == 0:
				break
			var enemy_tile = living_enemy_tiles[randi() % living_enemy_tiles.size()]
			var enemy_unit = enemy_area.unit_grid.units[enemy_tile]
			await _attack(player_unit, enemy_unit)
			await get_tree().create_timer(attack_cooldown).timeout
		i += 1

		# Enemy attacks
		if j < enemy_tiles.size() and player_tiles.size() > 0:
			var enemy_unit = enemy_area.unit_grid.units[enemy_tiles[j]]
			# Refresh living player tiles
			var living_player_tiles = []
			for tile in player_area.unit_grid.units.keys():
				var unit = player_area.unit_grid.units[tile]
				if unit and unit.stats and unit.stats.health > 0:
					living_player_tiles.append(tile)
			if living_player_tiles.size() == 0:
				break
			var player_tile = living_player_tiles[randi() % living_player_tiles.size()]
			var player_unit = player_area.unit_grid.units[player_tile]
			await _attack(enemy_unit, player_unit)
			await get_tree().create_timer(attack_cooldown).timeout
		j += 1

func _save_combat_results() -> void:
	# Collect unit states using original stored units (includes dead units)
	var updated_board_state = []
	var updated_hand_state = []
	
	# Restore all original board units (including those that died)
	for unit_data in original_board_units:
		var stats = unit_data["stats"]
		var tile = unit_data["tile"]
		var stored_max_health = unit_data["max_health_reached"]
		
		# Check if unit is still alive to get current buffed state
		var current_unit = player_area.unit_grid.units.get(tile)
		if current_unit and current_unit.stats:
			# Unit survived - use its current buffed stats but restore health
			stats = current_unit.stats.duplicate()
			var original_damaged_health = stats.health
			
			# Restore health based on unit type
			if stats.name == "Spectre":
				print("=== SPECTRE HEALTH RESTORATION ===")
				print("Current health: ", stats.health)
				print("Current attack: ", stats.attack)
				print("Max health reached: ", current_unit.max_health_reached)
				print("Base health: ", stats.base_health)
				print("Base attack: ", stats.base_attack)
				
				# The correct health should match the attack pattern
				var attack_bonus = stats.attack - stats.base_attack
				var correct_health = stats.base_health + attack_bonus
				
				print("Attack bonus: ", attack_bonus)
				print("Calculated correct health: ", correct_health)
				stats.health = correct_health
				print("Set health to: ", stats.health)
				print("=== END SPECTRE RESTORATION ===")
			else:
				# For all units, restore health to the highest value reached during combat
				var target_health = current_unit.max_health_reached if current_unit.max_health_reached > 0 else stats.base_health
				stats.health = target_health
				print("Unit ", stats.name, " health restored from ", original_damaged_health, " to ", target_health)
		else:
			# Unit died - check if we have final stats saved
			if dead_units_final_stats.has(tile):
				var final_data = dead_units_final_stats[tile]
				stats = final_data["stats"]
				var final_max_health = final_data["max_health_reached"]
				
				print("Unit ", stats.name, " died in combat, using final stats for respawn")
				if stats.name == "Spectre":
					# For Spectres, maintain any Soul Drain bonuses they had when they died
					var attack_bonus = stats.attack - stats.base_attack
					stats.health = stats.base_health + attack_bonus
					print("Respawning Spectre with Soul Drain bonuses: ", stats.attack, "/", stats.health)
				else:
					# For other units, restore to their max health reached
					stats.health = final_max_health if final_max_health > 0 else stats.base_health
					print("Respawning ", stats.name, " with health: ", stats.health)
			else:
				# Fallback to original stored stats (shouldn't happen with proper tracking)
				print("Unit ", stats.name, " died but no final stats found, using original")
				if stats.name == "Spectre":
					var attack_bonus = stats.attack - stats.base_attack
					stats.health = stats.base_health + attack_bonus
				else:
					stats.health = stored_max_health if stored_max_health > 0 else stats.base_health
		
		updated_board_state.append({
			"stats": stats,
			"tile": tile
		})
	
	# Save all hand units (use original stored states since hand units don't change during combat)
	for unit_data in original_hand_units:
		var stats = unit_data["stats"]
		var tile = unit_data["tile"]
		
		updated_hand_state.append({
			"stats": stats,
			"tile": tile
		})
	
	# Save the updated state back to GameState
	print("Combat ended - saving updated unit states with restored health")
	GameState.save_state(updated_board_state, updated_hand_state)

# Try to resurrect a dead player unit immediately if Shadeblade is present
var _resurrection_used_this_combat = false

func _try_shadow_resurrection(dead_unit: Unit) -> bool:
	# Check if resurrection was already used this combat
	if _resurrection_used_this_combat:
		print("Shadow Resurrection already used this combat")
		return false
	
	# Check if there's a living Shadeblade on the board
	var has_shadeblade = false
	for unit in player_area.unit_grid.units.values():
		if unit and unit.stats and unit.stats.health > 0 and unit.stats.name == "Shadeblade":
			has_shadeblade = true
			break
	
	if not has_shadeblade:
		print("No living Shadeblade found for resurrection")
		return false
	
	print("=== SHADOW RESURRECTION TRIGGERED ===")
	print("Shadeblade is immediately resurrecting ", dead_unit.stats.name)
	
	# Find the original tile where the unit died
	var original_tile = null
	for tile in player_area.unit_grid.units.keys():
		if player_area.unit_grid.units[tile] == dead_unit:
			original_tile = tile
			break
	
	# Find the next available slot (prefer not the original slot)
	var resurrection_tile = null
	
	# First, try to find any empty slot that's not the original
	for x in range(player_area.unit_grid.size.x):
		for y in range(player_area.unit_grid.size.y):
			var tile = Vector2i(x, y)
			if not player_area.unit_grid.units.has(tile) or player_area.unit_grid.units[tile] == null:
				if tile != original_tile:
					resurrection_tile = tile
					break
		if resurrection_tile:
			break
	
	# If no other empty slot found, use the original slot
	if not resurrection_tile:
		resurrection_tile = original_tile
		print("No alternative slot found - using original position")
	else:
		print("Resurrecting in new slot: ", resurrection_tile, " (original was: ", original_tile, ")")
	
	# Revive the unit with 1 HP
	dead_unit.stats.health = 1
	dead_unit.max_health_reached = max(dead_unit.max_health_reached, 1)
	
	# Add unit back to grid at resurrection tile
	if resurrection_tile:
		player_area.unit_grid.add_unit(resurrection_tile, dead_unit)
		dead_unit.global_position = player_area.get_global_from_tile(resurrection_tile)
	
	# Update the visual display
	if dead_unit.unit_hp:
		dead_unit.update_stat_display_health(dead_unit.unit_hp, dead_unit.stats.health, dead_unit.base_health, dead_unit.stats.health)
	
	# Mark resurrection as used for this combat
	_resurrection_used_this_combat = true
	
	# Show visual feedback
	print("💀➡️❤️ ", dead_unit.stats.name, " rises again with 1 HP at slot ", resurrection_tile, "!")
	print("    🌟 Shadeblade's power saves the day! 🌟")
	print("=== END SHADOW RESURRECTION ===")
	
	return true

# Store original unit states at the start of combat for later respawning
func _store_original_unit_states() -> void:
	original_board_units.clear()
	original_hand_units.clear()
	dead_units_final_stats.clear()
	# Reset resurrection for new combat
	_resurrection_used_this_combat = false
	
	# Store all board units
	for tile in player_area.unit_grid.units.keys():
		var unit = player_area.unit_grid.units[tile]
		if unit and unit.stats:
			original_board_units.append({
				"stats": unit.stats.duplicate(),
				"tile": tile,
				"max_health_reached": unit.max_health_reached
			})
	
	# Store all hand units
	for tile in hand_area.unit_grid.units.keys():
		var unit = hand_area.unit_grid.units[tile]
		if unit and unit.stats:
			original_hand_units.append({
				"stats": unit.stats.duplicate(),
				"tile": tile,
				"max_health_reached": unit.max_health_reached if unit.has_method("max_health_reached") else unit.stats.health
			})
	
	print("Stored original states: ", original_board_units.size(), " board units, ", original_hand_units.size(), " hand units")
