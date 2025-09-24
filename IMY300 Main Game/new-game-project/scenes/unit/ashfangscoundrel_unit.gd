@tool
class_name AshfangScoundrelUnit
extends Unit

# Scoundrel's Deal: Choose a unit to give +3 attack and -1 health
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
	
	# Store the original stats before applying temporary buff
	if not emitter.stats.has_meta("scoundrel_original_attack"):
		emitter.stats.set_meta("scoundrel_original_attack", emitter.stats.attack)
		emitter.stats.set_meta("scoundrel_original_health", emitter.stats.health)
	
	# Apply the scoundrel's deal: +3 attack, -1 health (temporary)
	emitter.stats.attack += 3
	emitter.stats.health -= 1
	
	# Make sure health doesn't go below 1
	if emitter.stats.health < 1:
		emitter.stats.health = 1
	
	# Mark this unit as having scoundrel's deal active
	emitter.stats.set_meta("scoundrel_deal_active", true)
	
	# Update the target's display
	emitter.set_stats(emitter.stats)
	
	# Clean up selection
	for unit in candidates:
		if is_instance_valid(unit):
			unit.set_selectable(false)
	
	stats.buff_used = true
	UnitMover.is_selecting_target = false
	UnitMover.selecting_unit = null
	
	# Only play sound if we're still in the scene
	if has_node("Buff"):
		$Buff.play()

func _ready() -> void:
	super._ready()

# Static function to reset all scoundrel deals after combat
static func reset_all_scoundrel_deals(play_area: PlayArea):
	for unit in play_area.unit_grid.units.values():
		if unit != null and unit.stats.has_meta("scoundrel_deal_active"):
			var original_attack = unit.stats.get_meta("scoundrel_original_attack")
			var original_health = unit.stats.get_meta("scoundrel_original_health")
			
			# Restore original stats
			unit.stats.attack = original_attack
			unit.stats.health = original_health
			
			# Clean up metadata
			unit.stats.remove_meta("scoundrel_deal_active")
			unit.stats.remove_meta("scoundrel_original_attack")
			unit.stats.remove_meta("scoundrel_original_health")
			
			# Update display
			unit.set_stats(unit.stats)
