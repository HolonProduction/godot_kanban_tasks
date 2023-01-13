@tool
extends AcceptDialog


const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")

var board_data: __BoardData
var data_uuid: String

@onready var category_select: OptionButton = %Category
@onready var description_edit: TextEdit = %Description


func _ready() -> void:
	about_to_popup.connect(update)


func update() -> void:
	if description_edit.text_changed.is_connected(__on_description_changed):
		description_edit.text_changed.disconnect(__on_description_changed)
	description_edit.text = board_data.get_task(data_uuid).description
	description_edit.text_changed.connect(__on_description_changed)

	title = "Task Details: " + board_data.get_task(data_uuid).title

	if category_select.item_selected.is_connected(__on_category_selected):
		category_select.item_selected.disconnect(__on_category_selected)
	category_select.clear()
	for uuid in board_data.get_categories():
		var i = Image.create(16, 16, false, Image.FORMAT_RGB8)
		i.fill(board_data.get_category(uuid).color)
		var t = ImageTexture.create_from_image(i)
		category_select.add_icon_item(t, board_data.get_category(uuid).title)
		category_select.set_item_metadata(-1, uuid)
		if uuid == board_data.get_task(data_uuid).category:
			category_select.select(category_select.item_count - 1)

	category_select.item_selected.connect(__on_category_selected)


# Workaround for godotengine/godot#70451
func popup_centered_ratio_no_fullscreen(ratio: float = 0.8) -> void:
	var viewport: Viewport = get_parent().get_viewport()
	popup(Rect2i(Vector2(viewport.position) + viewport.size / 2.0 - viewport.size * ratio / 2.0, viewport.size * ratio))


func __on_description_changed() -> void:
	board_data.get_task(data_uuid).description = description_edit.text


func __on_category_selected(index: int) -> void:
	board_data.get_task(data_uuid).category = category_select.get_item_metadata(index)
