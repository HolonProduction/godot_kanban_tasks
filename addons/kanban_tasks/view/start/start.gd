@tool
extends Control


signal create_board()
signal open_board()

@onready var create_board_button: LinkButton = %CreateBoard
@onready var open_board_button: LinkButton = %OpenBoard


func _ready() -> void:
	create_board_button.pressed.connect(func(): create_board.emit())
	open_board_button.pressed.connect(func(): open_board.emit())
