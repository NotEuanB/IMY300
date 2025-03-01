extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 16

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const WHITE_PIECE = preload("res://Assets/white_piece.png")
const BLACK_PIECE = preload("res://Assets/black_piece.png")

const BLACK_TURN = preload("res://Assets/black_turn.png")
const WHITE_TURN = preload("res://Assets/white_turn.png")

const PIECE_MOVE = preload("res://Assets/Piece_move.png")

@onready var pieces: Node2D = $Pieces
@onready var dots: Node2D = $Dots
@onready var turn: Sprite2D = $Turn
@onready var turn_label: Label = $"../Label"

#Variables
# -1 = black piece
# 0 = empty
# 1 = white piece

var board : Array
var white : bool = true
var state : bool = false
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

func _input(event):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			if !state && (white && board[var2][var1] > 0 || !white && board[var2][var1] < 0):
				selected_piece = Vector2(var2, var1)
				show_options()
				state = true
			elif state: set_move(var2, var1)
	
func is_mouse_out():
	if get_global_mouse_position().x < 0 || get_global_mouse_position().x > 144 || get_global_mouse_position().y > 0 || get_global_mouse_position().y < -144: return true
	return false

func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)

			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) , 
			-i * CELL_WIDTH - (CELL_WIDTH / 2))
			
			match board[i][j]:
				-1: holder.texture = BLACK_PIECE
				0: holder.texture = null
				1: holder.texture = WHITE_PIECE
	
	#turn_label.text = "White's Turn" if white else "Black's Turn"
	turn_label.global_position = Vector2(BOARD_SIZE * CELL_WIDTH / 2 - 40, -BOARD_SIZE * CELL_WIDTH - 40)
	
	if white:
		turn.texture = WHITE_TURN
		turn.scale.y = 1
		turn.global_position = Vector2(BOARD_SIZE * CELL_WIDTH / 2, -BOARD_SIZE * CELL_WIDTH + 128)  # Near White side
	else:
		turn.texture = BLACK_TURN
		turn.scale.y = -1
		turn.global_position = Vector2(BOARD_SIZE * CELL_WIDTH / 2, -128)  # Near Black side

func show_options():
	moves = get_moves()
	if moves == []:
		state = false
		return 
	show_dots()
	
func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH / 2), -i.x * CELL_WIDTH - (CELL_WIDTH / 2))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2, var1):
	for i in moves:
		if i.x == var2 && i.y == var1:
			# Move the selected piece to the new position
			board[var2][var1] = board[selected_piece.x][selected_piece.y]
			board[selected_piece.x][selected_piece.y] = 0
			
			# Check if this was a capture move
			if abs(var2 - selected_piece.x) == 2:  # Capture moves are always 2 squares away
				var captured_piece = Vector2((var2 + selected_piece.x) / 2, (var1 + selected_piece.y) / 2)
				board[captured_piece.x][captured_piece.y] = 0  # Remove the captured piece
			
			# Switch turns
			white = !white
			display_board()
			check_winner()
			break
	
	delete_dots()
	state = false

func check_winner():
	var white_pieces = 0
	var black_pieces = 0
	var white_has_moves = false
	var black_has_moves = false
	
	# Count pieces and check for available moves
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			if board[i][j] > 0:  # White piece
				white_pieces += 1
				selected_piece = Vector2(i, j)
				if get_moves():
					white_has_moves = true
			elif board[i][j] < 0:  # Black piece
				black_pieces += 1
				selected_piece = Vector2(i, j)
				if get_moves():
					black_has_moves = true

	# Determine the winner
	if white_pieces == 0:
		print("Black Wins!")
		end_game("Black Wins!")
	elif black_pieces == 0:
		print("White Wins!")
		end_game("White Wins!")
	elif white and not white_has_moves:
		print("Black Wins! (White has no moves)")
		end_game("Black Wins!")
	elif not white and not black_has_moves:
		print("White Wins! (Black has no moves)")
		end_game("White Wins!")

func end_game(winner_text: String):
	turn.texture = null  # Hide turn indicator
	turn_label.text = winner_text
	turn_label.add_theme_font_size_override("font_size", 24)
	turn_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Disable input to prevent further moves
	set_process_input(false)

func get_moves():
	var _moves = []
	match abs(board[selected_piece.x][selected_piece.y]):
		1: _moves = get_checker_moves()
	return _moves
	
func get_checker_moves():
	var _moves = []
	var directions = []
	
	if board[selected_piece.x][selected_piece.y] > 0: # White piece moves down
		directions = [Vector2(1,1), Vector2(1,-1)]
	else: # Black piece moves up
		directions = [Vector2(-1,1), Vector2(-1,-1)]

	for i in directions:
		var pos = selected_piece + i
		
		# Normal one-square movement
		if is_valid_position(pos) && is_empty(pos):
			_moves.append(pos)  
		
		# Capture logic: Check if an enemy is adjacent and an empty space is behind them
		var jump_pos = pos + i
		if is_valid_position(jump_pos) && is_empty(jump_pos) && is_enemy(pos):
			_moves.append(jump_pos)  # Allow jumping over an enemy
	
	return _moves


func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false

func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false

func is_enemy(pos : Vector2):
	if white && board[pos.x][pos.y] < 0 || !white && board[pos.x][pos.y] > 0: return true
	return false
