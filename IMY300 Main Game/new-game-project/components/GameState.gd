extends Node

var board_units: Array = []
var hand_units: Array = []

func save_state(board: Array, hand: Array) -> void:
	board_units = board.duplicate(true)
	hand_units = hand.duplicate(true)

func load_state() -> Array:
	return [board_units.duplicate(true), hand_units.duplicate(true)]

func reset_state() -> void:
	board_units = []
	hand_units = []
