class_name FamilyBonusDisplay
extends Control

@onready var family_container = $Panel/FamilyContainer
var family_labels = {}

func _ready():
	# Hide by default until there are active bonuses
	visible = false
	
	# Debug the node structure
	print("FamilyBonusDisplay _ready called")
	print("Children: ", get_children())
	if has_node("Panel"):
		print("Panel found, children: ", $Panel.get_children())
		if $Panel.has_node("FamilyContainer"):
			print("FamilyContainer found!")
		else:
			print("FamilyContainer NOT found in Panel")
	else:
		print("Panel NOT found!")
	
	# Wait for scene tree to be ready before updating display
	call_deferred("update_family_display")

func update_family_display():
	"""Update the display with current family bonuses"""
	# Try to get the family_container if it's null
	if not family_container and has_node("Panel/FamilyContainer"):
		family_container = $Panel/FamilyContainer
	
	if not family_container or not is_instance_valid(family_container):
		print("Warning: family_container is still null in update_family_display")
		# Try to create the container structure dynamically
		if has_node("Panel"):
			var panel = $Panel
			if not panel.has_node("FamilyContainer"):
				var container = VBoxContainer.new()
				container.name = "FamilyContainer"
				panel.add_child(container)
				family_container = container
				print("Created FamilyContainer dynamically")
		return
		
	clear_display()
	
	var active_bonuses = GameState.get_active_family_bonuses()
	var family_counts = GameState.get_family_counts()
	
	# Show panel only if there are active bonuses
	if active_bonuses.size() > 0:
		visible = true
		
		for family_type in active_bonuses:
			var bonuses = active_bonuses[family_type]
			var count = family_counts.get(family_type, 0)
			
			# Create family header
			var family_label = Label.new()
			family_label.text = "%s (%d units)" % [_get_family_name(family_type), count]
			family_label.add_theme_font_size_override("font_size", 16)
			family_label.add_theme_color_override("font_color", _get_family_color(family_type))
			family_container.add_child(family_label)
			
			# Add bonus descriptions
			for bonus in bonuses:
				var bonus_label = Label.new()
				bonus_label.text = "  • " + _get_bonus_description(bonus, family_type, count)
				bonus_label.add_theme_font_size_override("font_size", 12)
				bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				family_container.add_child(bonus_label)
			
			# Add spacing
			var spacer = Control.new()
			spacer.custom_minimum_size.y = 5
			family_container.add_child(spacer)
	else:
		visible = false

func clear_display():
	"""Clear all family display labels"""
	if not family_container or not is_instance_valid(family_container):
		print("Warning: family_container is null in clear_display")
		return
		
	for child in family_container.get_children():
		child.queue_free()

func refresh_display():
	"""Called when board state changes to refresh family bonuses"""
	call_deferred("update_family_display")

func _get_family_name(family_type) -> String:
	match family_type:
		0:  # RAT
			return "Rat Pack"
		1:  # GOLEM
			return "Golem Wall"
		2:  # IMP
			return "Imp Swarm"
		3:  # TROLL
			return "Troll Tribe"
		4:  # SPECTRE
			return "Spectre Host"
		5:  # LEVIATHAN
			return "Leviathan Depths"
		_:
			return "Unknown"

func _get_family_color(family_type) -> Color:
	match family_type:
		0:  # RAT
			return Color.BROWN
		1:  # GOLEM
			return Color.GRAY
		2:  # IMP
			return Color.RED
		3:  # TROLL
			return Color.GREEN
		4:  # SPECTRE
			return Color.PURPLE
		5:  # LEVIATHAN
			return Color.BLUE
		_:
			return Color.WHITE

func _get_bonus_description(bonus_name: String, _family_type, count: int) -> String:
	match bonus_name:
		"pack_hunter":
			var damage_bonus = (count - 1) * 2
			return "Pack Hunter: +%d damage per attack" % damage_bonus
		"swarm_tactics":
			return "Swarm Tactics: +%d health" % count
		"coordinated_assault":
			return "Coordinated Assault: +%d damage per attack" % count
		"infernal_growth":
			return "Infernal Growth: +%d health when enemy dies nearby"
		"armor":
			return "Armor: -%d damage taken" % count
		"stone_skin":
			return "Stone Skin: +%d health" % (count * 2)
		"fortress":
			return "Fortress: -2 damage taken (4+ Trolls)"
		"regeneration":
			return "Regeneration: +1 health per turn"
		"phase_dodge":
			var dodge_chance = min(count * 15, 75)
			return "Phase Dodge: %d%% chance to avoid damage" % dodge_chance
		"soul_drain":
			return "Soul Drain: +1 health when enemy unit dies"
		"abyssal_power":
			return "Abyssal Power: +2 damage and +2 health"
		"deep_current":
			return "Deep Current: +3 health per turn (4+ Leviathans)"
		_:
			return bonus_name