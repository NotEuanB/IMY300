extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 16

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const WHITE_PIECE = preload("res://Assets/white_piece.png")
const BLACK_PIECE = preload("res://Assets/black_piece.png")

const BLACK_TURN = preload("res://Assets/black_turn.png")
const WHITE_TURN = preload("res://Assets/white_turn.png")

@onready var pieces: Node2D = $Pieces
@onready var dots: Node2D = $Dots
@onready var turn: Sprite2D = $Turn

#Variables
# -1 = black piece
# 0 = empty
# 1 = white piece

var board : Array
var white : bool
var state : bool
var moves = []
var selected_piece : Vector2

func _ready() -> void:
	board.append([1, 0, 1, 0, 1, 0, 1, 0])
	board.append([0, 1, 0, 1, 0, 1, 0, 1])
	board.append([1, 0, 1, 0, 1, 0, 1, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-0, -1, -0, -1, -0, -1, -0, -1])
	board.append([-1, -0, -1, -0, -1, -0, -1, -0])
	board.append([-0, -1, -0, -1, -0, -1, -0, -1])
	
	display_board()

func display_board():
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			# Adjust for board's position
			var x_offset = 8
			var y_offset = -8
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) + x_offset , 
			-i * CELL_WIDTH - (CELL_WIDTH / 2) + y_offset)
			
			match board[i][j]:
				-1: holder.texture = BLACK_PIECE
				0: holder.texture = null
				1: holder.texture = WHITE_PIECE
