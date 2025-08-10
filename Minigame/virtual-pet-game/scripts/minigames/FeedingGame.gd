extends Control

@onready var food_container = $FoodContainer
@onready var pet_mouth = $PetMouth
@onready var score_label = $ScoreLabel
@onready var feed_button = $FeedButton
@onready var back_button = $BackButton

var food_scene = preload("res://scenes/minigames/Food.tscn")
var score = 0
var game_time = 30
var feeds_remaining = 5

var hunger_level: int = 100
var feeding_time: float = 0.0
var feeding_duration: float = 5.0

func _ready():
	start_feeding_game()
	start_game()
	feed_button.pressed.connect(_on_feed_pressed)
	back_button.pressed.connect(_on_back_pressed)
	update_ui()

func start_feeding_game():
	feeding_time = feeding_duration  

func _process(delta):
	if feeding_time > 0:
		feeding_time -= delta
		if feeding_time <= 0:
			end_feeding_game()

func end_feeding_game():
	hunger_level += 20  
	hunger_level = clamp(hunger_level, 0, 100) 

func get_hunger_level() -> int:
	return hunger_level

func start_game():
	score = 0
	spawn_food()
	var timer = Timer.new()
	timer.wait_time = game_time
	timer.one_shot = true
	timer.timeout.connect(self.end_game)
	add_child(timer)
	timer.start()

func end_game():
	get_tree().change_scene("res://scenes/Main.tscn")

func spawn_food():
	var food = food_scene.instance()
	food.position = Vector2(randf_range(50, get_viewport().size.x - 50), 0)
	food.connect("clicked", self, "_on_food_clicked")
	food_container.add_child(food)
	
	await get_tree().create_timer(2.0).timeout
	if get_tree().current_scene == self:
		spawn_food()

func _on_food_clicked(food_node):
	score += 10
	score_label.text = "Score: " + str(score)
	food_node.queue_free()
	
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.pet.feed()

	var bonus = float(score) / 10.0
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.game_data.hunger += bonus
		game_manager.game_data.happiness += bonus / 2.0

	get_tree().change_scene("res://scenes/Main.tscn")

func update_ui():
	score_label.text = "Score: " + str(score) + " | Feeds: " + str(feeds_remaining)
	feed_button.disabled = feeds_remaining <= 0
	
	if feeds_remaining <= 0:
		feed_button.text = "Game Complete!"

func _on_feed_pressed():
	if feeds_remaining > 0:
		score += 10
		feeds_remaining -= 1
		
		GameManager.game_data.hunger = min(100, GameManager.game_data.hunger + 20)
		GameManager.game_data.happiness = min(100, GameManager.game_data.happiness + 5)
		
		update_ui()
		
		if feeds_remaining <= 0:
			await get_tree().create_timer(1.0).timeout
			_on_back_pressed()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/UI/MainUI.tscn")
