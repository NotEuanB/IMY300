extends Node
class_name GameState

# the list of units (or cards) the player has bought:
var owned_units : Array = []
# e.g. your gold counter
var gold : int = 0

func reset():
	owned_units.clear()
	gold = 0
