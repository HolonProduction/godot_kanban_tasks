tool
extends AcceptDialog

onready var label := $VBoxContainer/RichTextLabel

func _ready():
	label.connect("meta_clicked", self, "__label_meta_clicked")

func __label_meta_clicked(meta):
	OS.shell_open(meta)
