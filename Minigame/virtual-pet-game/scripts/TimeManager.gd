extends Node
class_name TimeManager


signal time_passed(minutes)

var real_time_speed = 60  
var time_multiplier = 1
var last_time = 0

func _ready():
	last_time = Time.get_ticks_msec()

func _process(_delta):
	var current_time = Time.get_ticks_msec()
	var elapsed_ms = current_time - last_time

	var target_interval = (1000.0 / real_time_speed) * time_multiplier
	
	if elapsed_ms >= target_interval:
		emit_signal("time_passed", 1)
		last_time = current_time  

func get_real_time():
	var time = Time.get_datetime_dict_from_system()
	return time

func is_night_time() -> bool:
	var time = get_real_time()
	return time.hour >= 22 or time.hour <= 6

func speed_up_time(multiplier: int):
	time_multiplier = 1.0 / max(1, multiplier)  

func reset_time_speed():
	time_multiplier = 1
