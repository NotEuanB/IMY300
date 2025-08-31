extends Node
class_name EvolutionSystem

signal evolution_triggered(new_stage)

var evolution_requirements = {
	"healthy": {"health": 80},
	"strong": {"happiness": 70, "energy": 60},
	"smart": {"happiness": 90},
	"sick": {"health": 20}
}

var evolution_hierarchy = ["normal", "sick", "healthy", "strong", "smart"]
var last_evolution_time = 0
var evolution_cooldown = 5000

var health_regen_rate = 0.5 
var min_hunger_for_regen = 70  
var min_energy_for_regen = 60  

func check_evolution(data):
	data.age += 0.1
	
	regenerate_health(data)
	
	var current_time = Time.get_ticks_msec()
	if current_time - last_evolution_time < evolution_cooldown:
		return
	
	var best_evolution = find_best_evolution(data)
	
	if best_evolution != data.evolution_stage:
		trigger_evolution(best_evolution)
		last_evolution_time = current_time

func regenerate_health(data):
	if data.hunger >= min_hunger_for_regen and data.energy >= min_energy_for_regen:
		if data.health < 100:
			data.health = min(100, data.health + health_regen_rate)
			print("Health regenerating: ", data.health, " (Hunger: ", data.hunger, ", Energy: ", data.energy, ")")

func find_best_evolution(data) -> String:	
	if data.health <= 20:
		return "sick"
	
	if data.health > 50:
		if data.happiness >= 90:
			return "smart"
		
		elif data.happiness >= 70 and data.energy >= 60:
			return "strong"
		
		elif data.health >= 80:
			return "healthy"
	
	return "normal"

func trigger_evolution(new_stage: String):
	var game_manager = get_parent() 
	game_manager.game_data.evolution_stage = new_stage
	emit_signal("evolution_triggered", new_stage)
	print("Evolution triggered: ", new_stage)
