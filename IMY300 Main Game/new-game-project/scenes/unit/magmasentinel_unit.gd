@tool
class_name MagmaSentinelUnit
extends Unit

# Molten Taunt: Forces all enemies to attack this unit when it's alive
func _ready() -> void:
	super._ready()
	# Set taunt metadata so the combat system knows this unit has taunt
	if stats:
		stats.set_meta("has_taunt", true)
		print("Magma Sentinel: Taunt ability activated - enemies must target me!")
