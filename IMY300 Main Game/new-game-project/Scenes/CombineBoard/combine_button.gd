extends TextureButton

func _ready() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")

func _on_pressed() -> void:
	$CombineSprite/CombineAnimation.play("Combine_press")
	combine_units()
	await get_tree().create_timer(2.5).timeout
	var scene_tree = get_tree()
	scene_tree.change_scene_to_file("res://Scenes/ForestBoard/forestboard.tscn")

func _on_mouse_entered() -> void:
	$CombineSprite/CombineAnimation.play("Combine_hover")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_hover")

func _on_mouse_exited() -> void:
	$CombineSprite/CombineAnimation.play("Combine_idle")
	$"../Visuals/CombineBoardAnimation/CombineBoardAnimation".play("CombineBoard_idle")

var combination_db := {
	"Golem+Rat": preload("res://data/units/rolet.tres"), 
}

@export var slot_one_area: PlayArea
@export var slot_two_area: PlayArea
@export var hand_area: PlayArea
@export var unit_spawner: UnitSpawner

signal units_combined(combined_unit: Unit)

func combine_units() -> void:
	var slot_one_unit = _get_unit_in_slot(slot_one_area)
	var slot_two_unit = _get_unit_in_slot(slot_two_area)
	
	if not slot_one_unit or not slot_two_unit:
		push_error("Both slots must have a unit to combine.")
		return
	
	var combined_stats = _get_combined_stats(slot_one_unit, slot_two_unit)
	if combined_stats == null:
		return
	
	# Remove units from slots
	slot_one_area.unit_grid.remove_unit(_get_unit_tile(slot_one_area, slot_one_unit))
	slot_two_area.unit_grid.remove_unit(_get_unit_tile(slot_two_area, slot_two_unit))
	slot_one_unit.queue_free()
	slot_two_unit.queue_free()
	
	unit_spawner.spawn_unit(combined_stats)
	
	emit_signal("units_combined")

func _get_unit_in_slot(area: PlayArea) -> Unit:
	for unit in area.unit_grid.units.values():
		if unit:
			return unit
	return null

func _get_unit_tile(area: PlayArea, unit: Unit) -> Vector2i:
	for tile in area.unit_grid.units.keys():
		if area.unit_grid.units[tile] == unit:
			return tile
	return Vector2i(-1, -1)

func _get_combined_stats(slot_one_unit: Unit, slot_two_unit: Unit) -> UnitStats:
	var names = [slot_one_unit.stats.name, slot_two_unit.stats.name]
	names.sort()
	var key = "%s+%s" % [names[0], names[1]]
	var result_stats = combination_db.get(key, null)
	if result_stats == null:
		push_error("No combination found for %s + %s" % [slot_one_unit.stats.name, slot_two_unit.stats.name])
		return null
	return result_stats
