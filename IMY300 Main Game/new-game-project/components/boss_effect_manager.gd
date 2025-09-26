class_name BossEffectManager
extends Node

signal boss_effect_activated(effect_name: String)
signal boss_effect_triggered(effect_name: String, description: String)

var current_boss_effect: EnemyStats.BossEffectType = EnemyStats.BossEffectType.NONE
var current_boss_name: String = ""
var boss_unit: Unit = null  # Reference to the main boss unit

# Initialize boss effects when combat starts
func initialize_boss_effects(enemy_stats: EnemyStats) -> void:
	if not enemy_stats.is_boss:
		current_boss_effect = EnemyStats.BossEffectType.NONE
		current_boss_name = ""
		boss_unit = null
		return
	
	current_boss_effect = enemy_stats.boss_effect_type
	current_boss_name = enemy_stats.boss_name
	
	print("Boss Effect Manager: Initializing ", current_boss_name, " with effect ", EnemyStats.BossEffectType.keys()[current_boss_effect])
	
	# Apply initial boss effects
	_apply_initial_boss_effects()
	
	boss_effect_activated.emit(get_boss_effect_name())

# Find and store reference to the boss unit (usually the strongest enemy)
func set_boss_unit(enemy_area) -> void:
	if not enemy_area or current_boss_effect == EnemyStats.BossEffectType.NONE:
		return
	
	# Find the unit with highest health or attack as the "boss"
	var strongest_unit = null
	var highest_power = 0
	
	for unit in enemy_area.unit_grid.units.values():
		if unit and unit.stats:
			var power = unit.stats.attack + unit.stats.health
			if power > highest_power:
				highest_power = power
				strongest_unit = unit
	
	boss_unit = strongest_unit
	print("Boss Effect Manager: Boss unit identified - ", boss_unit.stats.name if boss_unit else "None")

# Apply effects that happen at the start of combat
func _apply_initial_boss_effects() -> void:
	match current_boss_effect:
		EnemyStats.BossEffectType.BLAZING_AURA:
			_apply_blazing_aura_initial()
		EnemyStats.BossEffectType.FROST_ARMOR:
			_apply_frost_armor_initial()
		EnemyStats.BossEffectType.SHADOW_CURSE:
			_apply_shadow_curse_initial()
		# Other effects don't need initial setup

# Called when combat round starts
func on_combat_round_start(player_area, enemy_area) -> void:
	match current_boss_effect:
		EnemyStats.BossEffectType.CHAOTIC_WINDS:
			_trigger_chaotic_winds(player_area, enemy_area)

# Called when any unit dies
func on_unit_death(dead_unit: Unit, _killer_unit: Unit) -> void:
	match current_boss_effect:
		EnemyStats.BossEffectType.DEATH_TAX:
			_trigger_death_tax(dead_unit)

# Called when a unit attacks another
func on_unit_attack(attacker: Unit, defender: Unit, _damage: int) -> void:
	match current_boss_effect:
		EnemyStats.BossEffectType.BLAZING_AURA:
			_trigger_blazing_retaliate(attacker, defender)

# ===== BOSS EFFECT IMPLEMENTATIONS =====

func _apply_blazing_aura_initial() -> void:
	boss_effect_triggered.emit("Blazing Aura", "All enemy units gain +1 attack and retaliate!")

func _apply_frost_armor_initial() -> void:
	boss_effect_triggered.emit("Frost Armor", "All enemy units gain +1 health and armor!")

func _apply_shadow_curse_initial() -> void:
	boss_effect_triggered.emit("Shadow Curse", "All player units lose 1 attack!")

func _trigger_chaotic_winds(player_area, enemy_area) -> void:
	if not player_area or not enemy_area:
		return
	
	print("Boss Effect: Chaotic Winds - Shuffling all unit positions!")
	boss_effect_triggered.emit("Chaotic Winds", "The winds scatter all units to new positions!")
	
	# Collect all units and their stats
	var all_player_units = []
	var all_enemy_units = []
	
	for unit in player_area.unit_grid.units.values():
		if unit and unit.stats:
			all_player_units.append(unit)
	
	for unit in enemy_area.unit_grid.units.values():
		if unit and unit.stats:
			all_enemy_units.append(unit)
	
	# Clear grids
	player_area.unit_grid.clear_all_units()
	enemy_area.unit_grid.clear_all_units()
	
	# Shuffle and redistribute
	all_player_units.shuffle()
	all_enemy_units.shuffle()
	
	_redistribute_units(player_area, all_player_units)
	_redistribute_units(enemy_area, all_enemy_units)

func _redistribute_units(area, units: Array) -> void:
	var placed_units = 0
	for row in range(area.unit_grid.size.y):
		for col in range(area.unit_grid.size.x):
			if placed_units >= units.size():
				break
			var tile = Vector2i(col, row)
			area.unit_grid.add_unit(tile, units[placed_units])
			placed_units += 1

func _trigger_death_tax(dead_unit: Unit) -> void:
	if not boss_unit or not boss_unit.stats:
		return
	
	print("Boss Effect: Death Tax - Boss gains +1/+1 from ", dead_unit.stats.name, "'s death")
	boss_effect_triggered.emit("Death Tax", boss_unit.stats.name + " grows stronger from death!")
	
	# Permanently increase boss stats
	boss_unit.stats.attack += 1
	boss_unit.stats.health += 1
	boss_unit.stats.base_attack += 1
	boss_unit.stats.base_health += 1
	
	# Update display
	if boss_unit.has_method("refresh_stats_display"):
		boss_unit.refresh_stats_display()

func _trigger_blazing_retaliate(attacker: Unit, defender: Unit) -> void:
	# Check if defender is an enemy unit (has blazing aura)
	if not defender or not defender.stats:
		return
	
	# For now, assume all enemy units have blazing aura when this boss effect is active
	# In a more complex system, you'd check defender's area or metadata
	var forest_board = get_tree().get_first_node_in_group("forestboard")
	if not forest_board:
		return
	
	var enemy_area = forest_board.get_enemy_area() if forest_board.has_method("get_enemy_area") else null
	if not enemy_area:
		return
	
	# Check if defender is in enemy area (has blazing aura)
	if defender in enemy_area.unit_grid.units.values():
		print("Boss Effect: Blazing Aura retaliate - ", defender.stats.name, " deals 1 damage back to attacker")
		if attacker and attacker.stats and attacker.stats.health > 0:
			attacker.take_damage(1, defender)

# Get user-friendly boss effect name
func get_boss_effect_name() -> String:
	match current_boss_effect:
		EnemyStats.BossEffectType.BLAZING_AURA:
			return "Blazing Aura"
		EnemyStats.BossEffectType.DEATH_TAX:
			return "Death Tax"
		EnemyStats.BossEffectType.CHAOTIC_WINDS:
			return "Chaotic Winds"
		EnemyStats.BossEffectType.FROST_ARMOR:
			return "Frost Armor"
		EnemyStats.BossEffectType.SHADOW_CURSE:
			return "Shadow Curse"
		_:
			return "No Effect"

# Get boss effect description
func get_boss_effect_description() -> String:
	match current_boss_effect:
		EnemyStats.BossEffectType.BLAZING_AURA:
			return "All enemy units gain +1 attack and deal 1 damage to attackers"
		EnemyStats.BossEffectType.DEATH_TAX:
			return "When any unit dies, this boss gains +1 attack and +1 health"
		EnemyStats.BossEffectType.CHAOTIC_WINDS:
			return "At the start of each round, randomly shuffle all unit positions"
		EnemyStats.BossEffectType.FROST_ARMOR:
			return "All enemy units gain +1 health and armor"
		EnemyStats.BossEffectType.SHADOW_CURSE:
			return "All player units lose 1 attack"
		_:
			return "No special effect"

# Check if currently fighting a boss
func is_boss_fight() -> bool:
	return current_boss_effect != EnemyStats.BossEffectType.NONE

# Get current boss name
func get_boss_name() -> String:
	return current_boss_name