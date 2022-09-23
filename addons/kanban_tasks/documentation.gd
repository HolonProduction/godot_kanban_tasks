@tool
extends AcceptDialog

@onready var label := $VBoxContainer/RichTextLabel

func _ready():
	label.meta_clicked.connect(__label_meta_clicked)

func __label_meta_clicked(meta):
	OS.shell_open(meta)
