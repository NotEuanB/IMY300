extends Node

var inventory: Array = []  # Stores purchased units

# Add a unit to the inventory
func add_to_inventory(unit: UnitStats) -> void:
	inventory.append(unit)

# Get the current inventory
func get_inventory() -> Array:
	return inventory

# Remove a unit from the inventory
func remove_from_inventory(unit: UnitStats) -> void:
	inventory.erase(unit)
