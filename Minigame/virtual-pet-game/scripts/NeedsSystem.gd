extends Node
class_name NeedsSystem

signal need_critical(need_name)

var depletion_rates = {
	"hunger": 0.05,   
	"happiness": 0.03, 
	"health": 0.01,    
	"energy": 0.04     
}

func deplete_needs(minutes_passed: int):
	var data = get_parent().game_data
	
	for need in depletion_rates.keys():
		data[need] -= depletion_rates[need] * minutes_passed
		data[need] = max(0, data[need])
		
		if data[need] <= 20:
			emit_signal("need_critical", need)
	
	if data.hunger <= 10 or data.happiness <= 10:
		data.health -= 0.05 * minutes_passed  
	
	if data.health <= 0:
		get_parent().emit_signal("pet_died")

func increase_need(need_name: String, amount: float):
	var data = get_parent().game_data
	data[need_name] = min(100, data[need_name] + amount)

func get_need_level(need_name: String) -> float:
	return get_parent().game_data.get(need_name, 0)
