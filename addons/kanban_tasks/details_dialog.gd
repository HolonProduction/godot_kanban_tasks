tool
extends AcceptDialog
# The dialog in which the details of a task
# can be edited (detail string, category, i.e.)

signal change()

onready var board: Control = get_node("../../../VBoxContainer")

var title: String
var details: String setget __set_details
var category

onready var details_edit: TextEdit = $VBoxContainer/TextEdit
onready var category_option: OptionButton = $VBoxContainer/HBoxContainer/OptionButton

func _ready():
	details_edit.connect("text_changed", self, "__on_details_edit_changed")
	category_option.connect("item_selected", self, "__on_category_selected")

func show_popup(title, details, category):
	if visible:
		hide()
	
	self.title = title
	__set_details(details)
	self.category = category
	
	category_option.clear()
	
	for c in len(board.categories):
		var i = Image.new()
		i.create(16, 16, false, Image.FORMAT_RGB8)
		i.fill(board.categories[c].color)
		var t = ImageTexture.new()
		t.create_from_image(i)
		category_option.add_icon_item(t, board.categories[c].title, c)
	
	category_option.select(board.category_index(category))
	
	window_title = self.title
	details_edit.text = self.details
	
	popup_centered()

func __on_category_selected(index):
	category = board.categories[index]
	emit_signal("change")

func __set_details(val):
	details = val
	if (
		is_instance_valid(details_edit)
		and not details_edit.text == val
	):
		details_edit.text = val

func __on_details_edit_changed():
	__set_details(details_edit.text)
	emit_signal("change")
