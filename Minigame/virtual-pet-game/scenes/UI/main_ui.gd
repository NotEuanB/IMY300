extends Control

@onready var hunger_bar = $VBoxContainer/HungerBar
@onready var happiness_bar = $VBoxContainer/HappinessBar
@onready var health_bar = $VBoxContainer/HealthBar
@onready var energy_bar = $VBoxContainer/EnergyBar

@onready var feed_button = $ButtonContainer/FeedButton
@onready var play_button = $ButtonContainer/PlayButton
@onready var sleep_button = $ButtonContainer/SleepButton
@onready var simulate_button = $ButtonContainer/SimulateButton
@onready var reset_button = $ButtonContainer/ResetButton

@onready var pet = $Pet

func _ready():
	setup_progress_bars()
	
	feed_button.pressed.connect(_on_feed_pressed)
	play_button.pressed.connect(_on_play_pressed)
	sleep_button.pressed.connect(_on_sleep_pressed)
	simulate_button.pressed.connect(_on_simulate_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	GameManager.set_pet(pet)

func setup_progress_bars():
	for bar in [hunger_bar, happiness_bar, health_bar, energy_bar]:
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 100

func _process(_delta):
	update_ui()

func update_ui():
	var data = GameManager.game_data
	hunger_bar.value = data.hunger
	happiness_bar.value = data.happiness
	health_bar.value = data.health
	energy_bar.value = data.energy
	
	simulate_button.text = "Simulate 20 Hours"
	reset_button.text = "Reset Pet"
	
	$EvolutionLabel.text = "Stage: " + data.evolution_stage if has_node("EvolutionLabel") else ""

	var is_sleeping = pet.is_sleeping
	feed_button.disabled = is_sleeping
	play_button.disabled = is_sleeping
	simulate_button.disabled = is_sleeping
	reset_button.disabled = is_sleeping
	sleep_button.disabled = is_sleeping

func _on_feed_pressed():
	if GameManager.pet:
		GameManager.pet.feed(20)

func _on_play_pressed():
	if GameManager.pet:
		GameManager.pet.play()

func _on_sleep_pressed():
	if GameManager.pet:
		GameManager.pet.sleep()

func _on_simulate_pressed():
	GameManager.simulate_time(20)

func _on_reset_pressed():
	GameManager.reset_pet()
