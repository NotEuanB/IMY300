@tool
class_name FamilyDisplay
extends VBoxContainer

# Display active family bonuses

var family_labels = {}

func _ready():
	update_family_display()

func update_family_display():
	# Clear existing labels
	for child in get_children():
		child.queue_free()
	family_labels.clear()
	
	# Get active family bonuses from GameState
	var active_bonuses = GameState.get_active_family_bonuses()
	var family_counts = GameState.get_family_counts()
	
	if active_bonuses.is_empty():
		var no_bonuses_label = Label.new()
		no_bonuses_label.text = "No Family Bonuses Active"
		no_bonuses_label.add_theme_color_override("font_color", Color.GRAY)
		add_child(no_bonuses_label)
		return
	
	# Display each active family
	for family_id in active_bonuses:
		var family_data = active_bonuses[family_id]
		var count = family_counts.get(family_id, 0)
		
		# Family header
		var header = Label.new()
		header.text = "%s (%d units)" % [family_data["name"], count]
		header.add_theme_color_override("font_color", Color.GOLD)
		add_child(header)
		
		# Active bonuses
		for bonus in family_data["bonuses"]:
			var bonus_label = Label.new()
			bonus_label.text = "• " + bonus
			bonus_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
			bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			add_child(bonus_label)
		
		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 10
		add_child(spacer)

# Call this when the board changes
func refresh_display():
	call_deferred("update_family_display")