@tool
class_name RatUnit
extends Unit

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
	UnitMover.selecting_rat = self

	for unit in candidates:
		if is_instance_valid(unit):
			unit.set_selectable(true)
			var callable = Callable(self, "_on_target_selected").bind(candidates)
			# Disconnect previous connections to avoid stacking
			if unit.is_connected("selected", callable):
				unit.disconnect("selected", callable)
			unit.connect("selected", callable, CONNECT_ONE_SHOT)

func _on_target_selected(emitter, candidates):
	emitter.stats.attack += 1
	emitter.stats.health += 1
	emitter.set_stats(emitter.stats)
	for unit in candidates:
		if is_instance_valid(unit):
			unit.set_selectable(false)
	stats.buff_used = true # <-- Mark as used on the stats resource
	UnitMover.is_selecting_target = false
	UnitMover.selecting_rat = null
	$Buff.play()
