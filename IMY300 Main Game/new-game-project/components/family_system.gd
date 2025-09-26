@tool
class_name FamilySystem
extends Node

# Define all family types
enum FamilyType {
	RAT,
	GOLEM, 
	IMP,
	TROLL,
	SPECTRE,
	LEVIATHAN
}

# Family bonus definitions
var family_bonuses = {
	FamilyType.RAT: {
		"name": "Swarm Tactics",
		"2": "All Rats gain +1 Attack",
		"3": "All Rats gain +1 Health", 
		"4": "Rats gain Pack Hunter: +1 damage per other Rat"
	},
	FamilyType.GOLEM: {
		"name": "Stone Bulwark",
		"2": "All units gain +1 Health",
		"3": "All Golems gain Armor (reduce damage by 1)",
		"4": "All Golems gain Fortress (immunity to first damage)"
	},
	FamilyType.IMP: {
		"name": "Infernal Fury", 
		"2": "All Imps gain +1 Attack",
		"3": "Imps deal 1 damage to random enemy when hurt",
		"4": "Imps gain Blazing (1 damage to adjacent enemies)"
	},
	FamilyType.TROLL: {
		"name": "Nature's Growth",
		"2": "All units gain +1 Health at combat start",
		"3": "All Trolls gain +1 permanent Health",
		"4": "Spawn 1/1 Vengeful Bog when a Troll dies"
	},
	FamilyType.SPECTRE: {
		"name": "Ethereal Presence",
		"2": "Spectres gain +1 Attack when enemy dies",
		"3": "25% chance for attacks on Spectres to miss", 
		"4": "When Spectre dies, reduce all enemy attacks by 1"
	},
	FamilyType.LEVIATHAN: {
		"name": "Deep Sea Mastery",
		"2": "All Leviathans start combat with +2 Health",
		"3": "All Leviathans heal 1 health per round",
		"4": "All Leviathans deal 1 damage to all enemies at combat start"
	}
}

# Track current family counts
var family_counts = {}

# Get family types for a unit based on its name and base components
func get_unit_families(unit_name: String) -> Array[FamilyType]:
	var families: Array[FamilyType] = []
	
	# Base units - single family
	match unit_name:
		"Rat":
			families.append(FamilyType.RAT)
		"Golem":
			families.append(FamilyType.GOLEM)
		"Flame Imp":
			families.append(FamilyType.IMP)
		"Moss Troll":
			families.append(FamilyType.TROLL)
		"Spectre":
			families.append(FamilyType.SPECTRE)
		"Tide Serpent":
			families.append(FamilyType.LEVIATHAN)
		
		# Combined units - inherit both parent families
		"Ashfang Scoundrel": # Flame Imp + Rat
			families.append_array([FamilyType.IMP, FamilyType.RAT])
		"Magma Sentinel": # Flame Imp + Golem
			families.append_array([FamilyType.IMP, FamilyType.GOLEM])
		"Bogbound Colossus": # Golem + Moss Troll
			families.append_array([FamilyType.GOLEM, FamilyType.TROLL])
		"Gravestone Warden": # Golem + Spectre
			families.append_array([FamilyType.GOLEM, FamilyType.SPECTRE])
		"Blightflame Shaman": # Flame Imp + Moss Troll
			families.append_array([FamilyType.IMP, FamilyType.TROLL])
		"Ashwraith": # Flame Imp + Spectre
			families.append_array([FamilyType.IMP, FamilyType.SPECTRE])
		"Rotshroud": # Moss Troll + Spectre
			families.append_array([FamilyType.TROLL, FamilyType.SPECTRE])
		"Shadeblade": # Rat + Spectre
			families.append_array([FamilyType.RAT, FamilyType.SPECTRE])
		"Rootsnare Bandit": # Moss Troll + Rat
			families.append_array([FamilyType.TROLL, FamilyType.RAT])
		"Bog Leviathan": # Moss Troll + Tide Serpent
			families.append_array([FamilyType.TROLL, FamilyType.LEVIATHAN])
		"Coral Colossus": # Golem + Tide Serpent
			families.append_array([FamilyType.GOLEM, FamilyType.LEVIATHAN])
		"Drowned Shade": # Spectre + Tide Serpent
			families.append_array([FamilyType.SPECTRE, FamilyType.LEVIATHAN])
		"Drownfang Raider": # Rat + Tide Serpent
			families.append_array([FamilyType.RAT, FamilyType.LEVIATHAN])
		"Steam Djinn": # Flame Imp + Tide Serpent
			families.append_array([FamilyType.IMP, FamilyType.LEVIATHAN])
		"Rolet": # Golem + Rat
			families.append_array([FamilyType.GOLEM, FamilyType.RAT])
		
		# Add other combinations as needed...
		_:
			print("Family System: Unknown unit type: ", unit_name)
	
	return families

# Count families on the board
func update_family_counts(board_units: Array) -> void:
	# Reset counts
	family_counts.clear()
	for family in FamilyType.values():
		family_counts[family] = 0
	
	# Count each unit's families
	for unit in board_units:
		if unit and unit.stats:
			var unit_families = get_unit_families(unit.stats.name)
			for family in unit_families:
				family_counts[family] += 1
	
	print("Family System: Current counts - ", family_counts)

# Update family auras (metadata only, no stat changes)
func update_family_auras(board_units: Array) -> void:
	update_family_counts(board_units)
	
	# Update family aura metadata for each unit
	for unit in board_units:
		if unit and unit.stats:
			# Clear old family metadata
			_clear_family_metadata(unit)
			
			# Set family aura metadata based on current counts
			var unit_families = get_unit_families(unit.stats.name)
			for family in unit_families:
				var count = family_counts[family]
				_set_family_aura_metadata(unit, family, count)
			
			# Refresh unit stat display to show family bonuses
			if unit.has_method("refresh_stats_display"):
				unit.refresh_stats_display()

# Clear family metadata without modifying stats
func _clear_family_metadata(unit: Unit) -> void:
	if unit and unit.stats:
		var family_bonus_keys = [
			"family_rat_attack", "family_rat_health", "family_pack_hunter",
			"family_golem_health", "family_golem_armor", "family_golem_fortress", 
			"family_imp_attack", "family_imp_retaliate", "family_imp_blazing",
			"family_troll_combat_health", "family_troll_health", "family_troll_attack",
			"family_spectre_death_bonus", "family_spectre_dodge", "family_spectre_death_debuff",
			"family_leviathan_health", "family_leviathan_regen", "family_leviathan_tsunami"
		]
		
		for key in family_bonus_keys:
			if unit.stats.has_meta(key):
				unit.stats.remove_meta(key)

# Set family aura metadata based on counts (no stat modifications)
func _set_family_aura_metadata(unit: Unit, family: FamilyType, count: int) -> void:
	if count < 2:
		return  # Need at least 2 for bonuses
	
	match family:
		FamilyType.RAT:
			_set_rat_aura_metadata(unit, count)
		FamilyType.GOLEM:
			_set_golem_aura_metadata(unit, count)
		FamilyType.IMP:
			_set_imp_aura_metadata(unit, count) 
		FamilyType.TROLL:
			_set_troll_aura_metadata(unit, count)
		FamilyType.SPECTRE:
			_set_spectre_aura_metadata(unit, count)
		FamilyType.LEVIATHAN:
			_set_leviathan_aura_metadata(unit, count)

# Aura metadata functions (no stat modifications)
func _set_rat_aura_metadata(unit: Unit, count: int) -> void:
	if count >= 2:
		unit.stats.set_meta("family_rat_attack", true)
	if count >= 3:
		unit.stats.set_meta("family_rat_health", true)
	if count >= 4:
		unit.stats.set_meta("family_pack_hunter", count - 1) # +damage per other rat

func _set_golem_aura_metadata(unit: Unit, count: int) -> void:
	# Check if this unit belongs to the Golem family
	var unit_families = get_unit_families(unit.stats.name)
	var is_golem_family = FamilyType.GOLEM in unit_families
	
	if count >= 2:
		# This affects ALL units, not just golems
		unit.stats.set_meta("family_golem_health", true)
	if count >= 3 and is_golem_family:
		unit.stats.set_meta("family_golem_armor", true)
	if count >= 4 and is_golem_family:
		unit.stats.set_meta("family_golem_fortress", true)

func _set_imp_aura_metadata(unit: Unit, count: int) -> void:
	# Check if this unit belongs to the Imp family (not just name containing "Imp")
	var unit_families = get_unit_families(unit.stats.name)
	var is_imp_family = FamilyType.IMP in unit_families
	
	if count >= 2 and is_imp_family:
		unit.stats.set_meta("family_imp_attack", true)
	if count >= 3 and is_imp_family:
		unit.stats.set_meta("family_imp_retaliate", true)
	if count >= 4 and is_imp_family:
		unit.stats.set_meta("family_imp_blazing", true)

func _set_troll_aura_metadata(unit: Unit, count: int) -> void:
	# Check if this unit belongs to the Troll family
	var unit_families = get_unit_families(unit.stats.name)
	var is_troll_family = FamilyType.TROLL in unit_families
	
	if count >= 2:
		# Combat start bonus for all units
		unit.stats.set_meta("family_troll_combat_health", true)
	if count >= 3 and is_troll_family:
		# Permanent health bonus for Troll family units
		unit.stats.set_meta("family_troll_health", true)
	if count >= 4 and is_troll_family:
		# Attack bonus for Troll family units
		unit.stats.set_meta("family_troll_attack", true)

func _set_spectre_aura_metadata(unit: Unit, count: int) -> void:
	# Check if this unit belongs to the Spectre family
	var unit_families = get_unit_families(unit.stats.name)
	var is_spectre_family = FamilyType.SPECTRE in unit_families
	
	if count >= 2 and is_spectre_family:
		unit.stats.set_meta("family_spectre_death_bonus", true)
	if count >= 3 and is_spectre_family:
		unit.stats.set_meta("family_spectre_dodge", true)
	if count >= 4 and is_spectre_family:
		unit.stats.set_meta("family_spectre_death_debuff", true)

func _set_leviathan_aura_metadata(unit: Unit, count: int) -> void:
	# Check if this unit belongs to the Leviathan family
	var unit_families = get_unit_families(unit.stats.name)
	var is_leviathan_family = FamilyType.LEVIATHAN in unit_families
	
	if count >= 2 and is_leviathan_family:
		unit.stats.set_meta("family_leviathan_health", true)
	if count >= 3 and is_leviathan_family:
		unit.stats.set_meta("family_leviathan_regen", true)
	if count >= 4 and is_leviathan_family:
		unit.stats.set_meta("family_leviathan_tsunami", true)

# Calculate dynamic family bonus for attack (used in combat)
func get_family_attack_bonus(unit: Unit) -> int:
	var bonus = 0
	
	if unit.stats.has_meta("family_rat_attack"):
		bonus += 1
	if unit.stats.has_meta("family_imp_attack"):
		bonus += 1
	if unit.stats.has_meta("family_troll_attack"):
		bonus += 1
	if unit.stats.has_meta("family_pack_hunter"):
		bonus += unit.stats.get_meta("family_pack_hunter")
	
	return bonus

# Calculate dynamic family bonus for health (used in combat)
func get_family_health_bonus(unit: Unit) -> int:
	var bonus = 0
	
	if unit.stats.has_meta("family_rat_health"):
		bonus += 1
	if unit.stats.has_meta("family_golem_health"):
		bonus += 1
	if unit.stats.has_meta("family_troll_health"):
		bonus += 1
	if unit.stats.has_meta("family_leviathan_health"):
		bonus += 2
	
	return bonus

# Get effective attack with all family bonuses (for display/tooltips)
func get_effective_attack(unit: Unit) -> int:
	return unit.stats.attack + get_family_attack_bonus(unit)

# Get effective health with all family bonuses (for display/tooltips)  
func get_effective_health(unit: Unit) -> int:
	return unit.stats.health + get_family_health_bonus(unit)

# Get active family bonuses for UI display
func get_active_bonuses() -> Dictionary:
	var active_bonuses = {}
	
	for family in family_counts:
		var count = family_counts[family]
		if count >= 2:
			active_bonuses[family] = {
				"name": family_bonuses[family]["name"],
				"count": count,
				"bonuses": []
			}
			
			if count >= 2:
				active_bonuses[family]["bonuses"].append(family_bonuses[family]["2"])
			if count >= 3:
				active_bonuses[family]["bonuses"].append(family_bonuses[family]["3"])
			if count >= 4:
				active_bonuses[family]["bonuses"].append(family_bonuses[family]["4"])
	
	return active_bonuses