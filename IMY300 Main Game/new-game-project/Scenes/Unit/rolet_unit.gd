@tool
class_name RoletUnit
extends Unit

# Stone Inheritance: On death, give current health to a random friendly unit for this combat only
func _ready() -> void:
	super._ready()
	print("Rolet: Stone Inheritance ability ready")
