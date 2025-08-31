extends Node

signal pet_evolved(evolution_type)
signal pet_died

var pet: Pet
var needs_system: NeedsSystem
var time_manager: TimeManager
var evolution_system: EvolutionSystem
var is_pet_dead = false

var game_data = {
	"pet_name": "Buddy",
	"hunger": 100,
	"happiness": 100,
	"health": 100,
	"energy": 100,
	"age": 0,
	"evolution_stage": "baby"
}

func _ready():
	needs_system = NeedsSystem.new()
	time_manager = TimeManager.new()
	evolution_system = EvolutionSystem.new()
	
	add_child(needs_system)
	add_child(time_manager)
	add_child(evolution_system)
	
	time_manager.connect("time_passed", Callable(self, "_on_time_passed"))
	needs_system.connect("need_critical", Callable(self, "_on_need_critical"))
	evolution_system.connect("evolution_triggered", Callable(self, "_on_evolution"))
	connect("pet_died", Callable(self, "_on_pet_died"))
	
	load_game_data()

func set_pet(pet_node: Pet):
	pet = pet_node

func _on_time_passed(minutes_passed):
	if not is_pet_dead:
		needs_system.deplete_needs(minutes_passed)
		evolution_system.check_evolution(game_data)
		save_game_data()

func _on_need_critical(need_name: String):
	print("Critical need: ", need_name)
	if pet:
		pet.show_emotion("sick")

func _on_evolution(evolution_type: String):
	print("Pet evolved to: ", evolution_type)
	if pet:
		pet.update_sprite()

func _on_pet_died():
	is_pet_dead = true
	print("Pet has died!")
	if pet:
		pet.show_emotion("sick")
		pet.sprite.modulate = Color.GRAY

func reset_pet():
	is_pet_dead = false
	game_data = {
		"pet_name": "Buddy",
		"hunger": 100,
		"happiness": 100,
		"health": 100,
		"energy": 100,
		"age": 0,
		"evolution_stage": "baby"
	}
	if pet:
		pet.update_sprite()

func simulate_time(hours: int):
	print("Simulating ", hours, " hours...")
	for i in range(hours * 6):
		_on_time_passed(10)
		await get_tree().create_timer(0.01).timeout
	print("Simulation complete!")

func save_game_data():
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_data))
		file.close()

func load_game_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				game_data = json.get_data()
			else:
				print("Error parsing JSON: ", json.get_error_message())
