extends Control
class_name BossEffectDisplay

@onready var boss_name_label: Label = $VBoxContainer/BossNameLabel
@onready var effect_name_label: Label = $VBoxContainer/EffectNameLabel  
@onready var effect_description_label: Label = $VBoxContainer/EffectDescriptionLabel
@onready var boss_effect_manager = null

func _ready():
	# Connect to the forest board's boss effect manager
	var forest_board = get_tree().get_first_node_in_group("forestboard")
	if forest_board and forest_board.boss_effect_manager:
		boss_effect_manager = forest_board.boss_effect_manager
		boss_effect_manager.boss_effect_activated.connect(_on_boss_effect_activated)
		boss_effect_manager.boss_effect_triggered.connect(_on_boss_effect_triggered)
		
		# Check if we're already in a boss fight
		if boss_effect_manager.is_boss_fight():
			_show_boss_effect()
		else:
			visible = false
	else:
		visible = false

func _show_boss_effect():
	if not boss_effect_manager:
		return
		
	boss_name_label.text = boss_effect_manager.get_boss_name()
	effect_name_label.text = boss_effect_manager.get_boss_effect_name()
	effect_description_label.text = boss_effect_manager.get_boss_effect_description()
	visible = true
	
	# Add visual flair
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func _on_boss_effect_activated(effect_name: String):
	print("Boss Effect Display: Effect activated - ", effect_name)
	_show_boss_effect()

func _on_boss_effect_triggered(effect_name: String, description: String):
	print("Boss Effect Display: Effect triggered - ", effect_name, ": ", description)
	
	# Flash the effect display
	var original_color = modulate
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.2, 1.2, 1), 0.2)
	tween.tween_property(self, "modulate", original_color, 0.3)
	
	# Show temporary popup text
	_show_trigger_popup(description)

func _show_trigger_popup(text: String):
	# Create a temporary label for the effect trigger
	var popup = Label.new()
	popup.text = text
	popup.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	popup.get_theme_stylebox("normal").bg_color = Color(0.2, 0.2, 0.2, 0.8)
	popup.get_theme_stylebox("normal").corner_radius_top_left = 8
	popup.get_theme_stylebox("normal").corner_radius_top_right = 8
	popup.get_theme_stylebox("normal").corner_radius_bottom_left = 8
	popup.get_theme_stylebox("normal").corner_radius_bottom_right = 8
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(0, -50)
	popup.size = Vector2(300, 30)
	add_child(popup)
	
	# Animate popup
	popup.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.parallel().tween_property(popup, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(popup, "position", Vector2(0, -80), 0.3)
	tween.tween_delay(2.0)
	tween.parallel().tween_property(popup, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.parallel().tween_property(popup, "position", Vector2(0, -120), 0.5)
	tween.tween_callback(popup.queue_free)