extends CharacterBody2D
class_name Pet

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var state_label = $StateLabel  # Reference to the label

var current_emotion = "neutral"
var current_evolution = "baby"
var is_sleeping = false

func _ready():
	if not sprite.texture:
		var image = Image.create(200, 200, false, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture
	
	update_sprite()

func feed(amount: int = 20):
	GameManager.game_data.hunger = min(100, GameManager.game_data.hunger + amount)
	GameManager.game_data.happiness = min(100, GameManager.game_data.happiness + 10)
	show_emotion("happy")
	print("Pet fed! Hunger: ", GameManager.game_data.hunger)

func play():
	GameManager.game_data.happiness = min(100, GameManager.game_data.happiness + 25)
	GameManager.game_data.energy = max(0, GameManager.game_data.energy - 15)
	show_emotion("excited")
	print("Pet played! Happiness: ", GameManager.game_data.happiness)

func sleep():
	if is_sleeping:
		print("Pet is already sleeping!")
		return
	
	is_sleeping = true
	GameManager.game_data.energy = min(100, GameManager.game_data.energy + 30) 
	show_emotion("sleepy") 
	state_label.text = "Sleeping | Stage: " + current_evolution.capitalize()
	print("Pet is now sleeping. Energy: ", GameManager.game_data.energy)

	var timer = Timer.new()
	timer.wait_time = 5.0 
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_sleep_complete"))
	add_child(timer)
	timer.start()

func _on_sleep_complete():
	print("Pet has finished sleeping.")
	wake_up()

func wake_up():
	if not is_sleeping:
		print("Pet is already awake!")
		return
	
	is_sleeping = false
	show_emotion("neutral") 
	state_label.text = "Awake | Stage: " + current_evolution.capitalize() 
	print("Pet woke up! Energy: ", GameManager.game_data.energy)

func show_emotion(emotion: String = ""):
	if GameManager.game_data.hunger < 30:
		sprite.modulate = Color(1, 0.5, 0)
		state_label.text = "Hungry | Stage: " + current_evolution.capitalize()
		print("Pet is hungry!")
	elif GameManager.game_data.energy < 30:
		sprite.modulate = Color(0, 0, 1) 
		state_label.text = "Tired | Stage: " + current_evolution.capitalize()
		print("Pet is tired!")
	elif GameManager.game_data.happiness < 30:
		sprite.modulate = Color(1, 0, 1) 
		state_label.text = "Unhappy | Stage: " + current_evolution.capitalize()
		print("Pet is unhappy!")
	else:
		if emotion == "":
			emotion = current_emotion
		current_emotion = emotion
		match emotion:
			"happy":
				sprite.modulate = Color.YELLOW
				state_label.text = "Happy | Stage: " + current_evolution.capitalize()
			"excited":
				sprite.modulate = Color.ORANGE
				state_label.text = "Excited | Stage: " + current_evolution.capitalize()
			"sleepy":
				sprite.modulate = Color.BLUE
				state_label.text = "Sleepy | Stage: " + current_evolution.capitalize()
			"sick":
				sprite.modulate = Color.RED
				state_label.text = "Sick | Stage: " + current_evolution.capitalize()
			_:
				sprite.modulate = Color.WHITE
				state_label.text = "Neutral | Stage: " + current_evolution.capitalize()

func update_sprite():
	var evolution_stage = GameManager.game_data.evolution_stage
	
	if current_evolution == evolution_stage:
		return
		
	current_evolution = evolution_stage
	print("Pet sprite updated to: ", evolution_stage)
	
	if sprite:
		match evolution_stage:
			"normal":
				sprite.modulate = Color.WHITE
			"healthy":
				sprite.modulate = Color.GREEN
			"strong":
				sprite.modulate = Color.RED
			"smart":
				sprite.modulate = Color.BLUE
			"sick":
				sprite.modulate = Color.GRAY
	
	state_label.text = state_label.text.split("|")[0].strip_edges() + " | Stage: " + current_evolution.capitalize()
