@tool
extends MarginContainer

## The visual representation of a task.


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __Shortcuts := preload("res://addons/kanban_tasks/view/shortcuts.gd")
const __Filter := preload("res://addons/kanban_tasks/view/filter.gd")
const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __EditLabel := preload("res://addons/kanban_tasks/edit_label/edit_label.gd")

enum ACTIONS {
	DETAILS,
	RENAME,
	DELETE,
	DUPLICATE,
}

const COLOR_WIDTH: int = 8

var board_data: __BoardData
var data_uuid: String

@onready var panel_container: PanelContainer = %Panel
@onready var title_label: __EditLabel = %Title
@onready var description_label: Label = %Description
@onready var edit_button: Button = %Edit
@onready var context_menu: PopupMenu = %ContextMenu

var __style_focus: StyleBoxFlat
var __style_panel: StyleBoxFlat


func _ready() -> void:
	__style_focus = StyleBoxFlat.new()
	__style_focus.set_border_width_all(1)
	__style_focus.draw_center = false

	__style_panel = StyleBoxFlat.new()
	__style_panel.set_border_width_all(0)
	__style_panel.border_width_left = COLOR_WIDTH
	__style_panel.draw_center = false
	panel_container.add_theme_stylebox_override(&"panel", __style_panel)

	update()
	board_data.get_task(data_uuid).changed.connect(update)

	context_menu.id_pressed.connect(__action)

	notification(NOTIFICATION_THEME_CHANGED)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		__update_context_menu()
		context_menu.position = get_global_mouse_position()
		context_menu.popup()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and event.is_double_click():
		__action(ACTIONS.DETAILS)


func _shortcut_input(event: InputEvent) -> void:
	if not __Shortcuts.should_handle_shortcut(self):
		return
	var __shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)
	if not event.is_echo() and event.is_pressed():
		if __shortcuts.delete.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.DELETE)
		elif __shortcuts.confirm.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.DETAILS)
		elif __shortcuts.rename.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.RENAME)
		elif __shortcuts.duplicate.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.DUPLICATE)


func _notification(what: int) -> void:
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if panel_container:
				var tab_panel = get_theme_stylebox(&"panel", &"TabContainer")
				if tab_panel is StyleBoxFlat:
					__style_panel.bg_color = tab_panel.bg_color
					__style_panel.draw_center = true
				else:
					__style_panel.draw_center = false
			if edit_button:
				edit_button.icon = get_theme_icon(&"Edit", &"EditorIcons")
		NOTIFICATION_DRAW:
			if has_focus():
				__style_focus.draw(
					get_canvas_item(),
					Rect2(
						panel_container.get_global_rect().position - get_global_rect().position,
						panel_container.size
					),
				)


func update() -> void:
	__style_focus.border_color = \
		board_data.get_category(board_data.get_task(data_uuid).category).color

	__style_panel.border_color = \
		board_data.get_category(board_data.get_task(data_uuid).category).color

	description_label.text = board_data.get_task(data_uuid).description
	description_label.visible = description_label.text.strip_edges().length() != 0

	if title_label.text_changed.is_connected(__set_title):
		title_label.text_changed.disconnect(__set_title)
	title_label.text = board_data.get_task(data_uuid).title
	title_label.text_changed.connect(__set_title)

	tooltip_text = board_data.get_category(board_data.get_task(data_uuid).category).title \
			+ ": " + board_data.get_task(data_uuid).title


func show_edit(intention: __EditLabel.INTENTION) -> void:
	title_label.show_edit(intention)


func apply_filter(filter: __Filter) -> void:
	if filter.text.length() == 0:
		show()
		return

	var filter_simple := __simplify_string(filter.text)
	var title := __simplify_string(board_data.get_task(data_uuid).title)
	var description := __simplify_string(board_data.get_task(data_uuid).description)

	if (title.matchn("*"+filter_simple+"*") or description.matchn("*"+filter_simple+"*")):
		show()
	else:
		hide()


func get_drag_data(position: Vector2) -> void:
	var control = Control.new()
	var rect = ColorRect.new()
	control.add_child(rect)
	rect.size = get_rect().size
	rect.position = -position
	#rect.color = category.color
	set_drag_preview(control)
	return self


func __simplify_string(string: String) -> String:
	return string.replace(" ", "").replace("\t", "")


func __update_context_menu():
	context_menu.clear()
	context_menu.add_item("Details", ACTIONS.DETAILS)

	context_menu.add_separator()

	context_menu.add_icon_item(get_theme_icon("Rename", "EditorIcons"), "Rename", ACTIONS.RENAME)
	#context_menu.set_item_shortcut(context_menu.get_item_index(ACTIONS.RENAME), board.shortcut_rename)

	context_menu.add_icon_item(get_theme_icon("Duplicate", "EditorIcons"), "Duplicate", ACTIONS.DUPLICATE)
	#context_menu.set_item_shortcut(context_menu.get_item_index(ACTIONS.DUPLICATE), board.shortcut_duplicate)

	context_menu.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Delete", ACTIONS.DELETE)
	#context_menu.set_item_shortcut(context_menu.get_item_index(ACTIONS.DELETE), board.shortcut_delete)


func __action(action):
	match(action):
		ACTIONS.DELETE:
			#board.delete_task(self)
			emit_signal("change")
		ACTIONS.DETAILS:
			#show_details()
			pass
		ACTIONS.DUPLICATE:
			#var n = copy()
			#get_owner().add_task(n)
			#get_owner().move_task(len(get_owner().tasks)-1, get_owner().tasks.find(self)+1)
			#await get_tree().create_timer(0.0).timeout
			#n.grab_focus()
			pass
		ACTIONS.RENAME:
			if context_menu.visible:
				await context_menu.popup_hide
			title_label.show_edit()


func __set_title(value: String) -> void:
	board_data.get_task(data_uuid).title = value
