@tool
class_name MagmaSentinelUnit
extends Unit

# Molten Taunt: Forces all enemies to attack this unit when it's alive
func _ready() -> void:
	super._ready()
	# Wait a frame to ensure stats are fully initialized
	call_deferred("_setup_taunt")

func on_played(_play_area: PlayArea) -> void:
	# Ensure taunt is set when played
	_setup_taunt()
	print("Magma Sentinel: Played on board - taunt should now be active!")

func _setup_taunt() -> void:
	if stats:
		# Only set up taunt if it's not already set to avoid spam
		if not stats.get_meta("has_taunt", false):
			stats.set_meta("has_taunt", true)
			print("Magma Sentinel: Taunt ability activated - enemies must target me!")
			print("Magma Sentinel: Stats name = ", stats.name)
			print("Magma Sentinel: Stats has_taunt = ", stats.get_meta("has_taunt", false))
		else:
			print("Magma Sentinel: Taunt already active")
	else:
		print("Magma Sentinel: WARNING - No stats available for taunt setup")
		# Try again next frame if stats aren't ready
		call_deferred("_setup_taunt")

# Override set_stats to ensure taunt persists when stats are updated
func set_stats(new_stats: Resource) -> void:
	super.set_stats(new_stats)
	# Reapply taunt after stats change
	_setup_taunt()
