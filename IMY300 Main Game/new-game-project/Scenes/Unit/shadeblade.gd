@tool
class_name ShadebladeUnit
extends Unit

# Shadow Resurrection: Choose ally to buff +1/+1, first ally death each combat gets revived with 1 HP
func on_played(play_area: PlayArea) -> void:
	print("=== SHADEBLADE ON_PLAYED CALLED ===")
	print("Stats: ", stats)
	print("Buff used: ", stats.buff_used if stats else "NO STATS")
	print("Is selecting target: ", UnitMover.is_selecting_target)
	
	if stats.buff_used or UnitMover.is_selecting_target:
		print("Early return - buff used or already selecting")
		return

	var candidates: Array = []
	for unit in play_area.unit_grid.units.values():
		if unit != null and unit != self:
			candidates.append(unit)
	
	print("Found ", candidates.size(), " potential targets")
	if candidates.size() == 0:
		print("No candidates found - returning")
		return

	print("Setting up target selection...")
	self.set_selectable(false)
	UnitMover.is_selecting_target = true
	UnitMover.selecting_unit = self

	for unit in candidates:
		if is_instance_valid(unit):
			print("Making unit selectable: ", unit.stats.name)
			unit.set_selectable(true)
			var callable = Callable(self, "_on_target_selected").bind(candidates)
			# Disconnect previous connections to avoid stacking
			if unit.is_connected("selected", callable):
				unit.disconnect("selected", callable)
			unit.connect("selected", callable, CONNECT_ONE_SHOT)
	
	print("Shadeblade waiting for target selection...")

func _on_target_selected(emitter, candidates):
	# Give the target +1/+1 (same as Rat)
	emitter.stats.attack += 1
	emitter.stats.health += 1
	emitter.set_stats(emitter.stats)
	
	# Clean up selection
	for unit in candidates:
		if is_instance_valid(unit):
			unit.set_selectable(false)
	
	stats.buff_used = true
	UnitMover.is_selecting_target = false
	UnitMover.selecting_unit = null
	$Buff.play()
	
	print("Shadeblade blessed ", emitter.stats.name, " with shadow protection")

# Note: The resurrection logic will be implemented in the ForestBoard
# We'll store a flag to indicate this unit provides resurrection
func _ready() -> void:
	super._ready()
	print("!!! SHADEBLADE SCRIPT IS WORKING - _READY CALLED !!!")
	print("Stats exist: ", stats != null)
	# Mark that this unit provides shadow resurrection
	if stats:
		# Reset buff_used for Shadeblade (even if parent Rat used its buff)
		stats.buff_used = false
		stats.set_meta("provides_shadow_resurrection", true)
		print("Shadeblade ready with Shadow Resurrection ability - metadata set, buff_used reset")
		print("Stats name: ", stats.name)
		print("Buff used now: ", stats.buff_used)
	else:
		print("WARNING: Shadeblade has no stats in _ready()")
		call_deferred("_check_stats_later")

func _check_stats_later():
	print("Checking stats later - Stats exist: ", stats != null)
	if stats:
		stats.buff_used = false
		stats.set_meta("provides_shadow_resurrection", true)
		print("Stats set up later: ", stats.name)
