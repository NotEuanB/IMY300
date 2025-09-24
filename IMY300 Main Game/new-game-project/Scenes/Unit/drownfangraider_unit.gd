@tool
class_name DrownfangRaiderUnit
extends Unit

# Depths Empowerment: Choose a friendly unit to give +1/+1 permanently and "Submerge" (first death becomes 1 HP instead)
func on_played(play_area: PlayArea) -> void:
	if stats.buff_used or UnitMover.is_selecting_target:
		return

	var candidates: Array = []
	for unit in play_area.unit_grid.units.values():
		if unit != null and unit != self:
			candidates.append(unit)
	
	if candidates.size() == 0:
		return

	self.set_selectable(false)
	UnitMover.is_selecting_target = true
	UnitMover.selecting_unit = self

	for unit in candidates:
		if is_instance_valid(unit):
			unit.set_selectable(true)
			var callable = Callable(self, "_on_target_selected").bind(candidates)
			# Disconnect previous connections to avoid stacking
			if unit.is_connected("selected", callable):
				unit.disconnect("selected", callable)
			unit.connect("selected", callable, CONNECT_ONE_SHOT)

func _on_target_selected(emitter, candidates):
	# Double-check that we're still in a valid state (scene hasn't changed)
	if not is_instance_valid(self) or not is_instance_valid(emitter):
		return
	
	# Apply the depths empowerment: +1/+1 permanently
	emitter.stats.attack += 1
	emitter.stats.health += 1
	
	# Also update base stats to make the buff truly permanent
	if emitter.stats.has_method("get") and "base_attack" in emitter.stats:
		emitter.stats.base_attack += 1
		emitter.stats.base_health += 1
	
	# Grant Submerge ability - survive first death with 1 HP
	if not emitter.stats.has_meta("submerge_active"):
		emitter.stats.set_meta("submerge_active", true)
		print("Drownfang Raider: Granted Submerge to ", emitter.stats.name)
	
	# Update the target's display
	emitter.set_stats(emitter.stats)
	
	# Clean up selection
	for unit in candidates:
		if is_instance_valid(unit):
			unit.set_selectable(false)
	
	stats.buff_used = true
	UnitMover.is_selecting_target = false
	UnitMover.selecting_unit = null
	
	print("Drownfang Raider: Empowered ", emitter.stats.name, " with +1/+1 and Submerge")
	
	# Only play sound if we're still in the scene
	if has_node("Buff"):
		$Buff.play()

func _ready() -> void:
	super._ready()

# Static function to handle Submerge ability when units take lethal damage
static func handle_submerge_ability(unit: Unit) -> bool:
	if not unit or not unit.stats:
		return false
	
	# Check if this unit has Submerge and hasn't used it yet
	if unit.stats.has_meta("submerge_active"):
		print("Drownfang Raider: ", unit.stats.name, " used Submerge ability - surviving with 1 HP!")
		# Remove the submerge ability (one-time use)
		unit.stats.remove_meta("submerge_active")
		# Set health to 1 instead of dying
		unit.stats.health = 1
		unit.set_stats(unit.stats)
		return true  # Indicate that death was prevented
	
	return false  # Unit dies normally