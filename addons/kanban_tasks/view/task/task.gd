@tool
extends MarginContainer

## The visual representation of a task.


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __Shortcuts := preload("res://addons/kanban_tasks/view/shortcuts.gd")
const __EditContext := preload("res://addons/kanban_tasks/view/edit_context.gd")
const __Filter := preload("res://addons/kanban_tasks/view/filter.gd")
const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __EditLabel := preload("res://addons/kanban_tasks/edit_label/edit_label.gd")
const __TaskData := preload("res://addons/kanban_tasks/data/task.gd")
const __DetailsScript := preload("res://addons/kanban_tasks/view/details/details.gd")

enum ACTIONS {
	DETAILS,
	RENAME,
	DELETE,
	DUPLICATE,
}

const COLOR_WIDTH: int = 8

var board_data: __BoardData
var data_uuid: String

var __style_focus: StyleBoxFlat
var __style_panel: StyleBoxFlat

@onready var panel_container: PanelContainer = %Panel
@onready var title_label: __EditLabel = %Title
@onready var description_label: Label = %Description
@onready var edit_button: Button = %Edit
@onready var context_menu: PopupMenu = %ContextMenu
@onready var details: __DetailsScript = %Details


func _ready() -> void:
	__style_focus = StyleBoxFlat.new()
	__style_focus.set_border_width_all(1)
	__style_focus.draw_center = false

	__style_panel = StyleBoxFlat.new()
	__style_panel.set_border_width_all(0)
	__style_panel.border_width_left = COLOR_WIDTH
	__style_panel.draw_center = false
	panel_container.add_theme_stylebox_override(&"panel", __style_panel)

	context_menu.id_pressed.connect(__action)
	edit_button.pressed.connect(__action.bind(ACTIONS.DETAILS))

	notification(NOTIFICATION_THEME_CHANGED)

	await get_tree().create_timer(0.0).timeout
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)

	update()
	board_data.get_task(data_uuid).changed.connect(update)

	if data_uuid == ctx.focus:
		ctx.focus = ""
		grab_focus()

	ctx.filter_changed.connect(__apply_filter)
	__apply_filter()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		__update_context_menu()
		context_menu.position = get_global_mouse_position()
		if not get_window().gui_embed_subwindows:
			context_menu.position += get_window().position
		context_menu.popup()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and event.is_double_click():
		__action(ACTIONS.DETAILS)


func _shortcut_input(event: InputEvent) -> void:
	if not __Shortcuts.should_handle_shortcut(self):
		return
	var shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)
	if not event.is_echo() and event.is_pressed():
		if shortcuts.delete.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.DELETE)
		elif shortcuts.confirm.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.DETAILS)
		elif shortcuts.rename.matches_event(event):
			get_viewport().set_input_as_handled()
			__action(ACTIONS.RENAME)
		elif shortcuts.duplicate.matches_event(event):
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
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)

	__style_focus.border_color = \
		board_data.get_category(board_data.get_task(data_uuid).category).color

	__style_panel.border_color = \
		board_data.get_category(board_data.get_task(data_uuid).category).color

	description_label.text = board_data.get_task(data_uuid).description
	description_label.visible = ctx.settings.show_description_preview and description_label.text.strip_edges().length() != 0

	if title_label.text_changed.is_connected(__set_title):
		title_label.text_changed.disconnect(__set_title)
	title_label.text = board_data.get_task(data_uuid).title
	title_label.text_changed.connect(__set_title)

	tooltip_text = board_data.get_category(board_data.get_task(data_uuid).category).title \
			+ ": " + board_data.get_task(data_uuid).title

	queue_redraw()


func show_edit(intention: __EditLabel.INTENTION) -> void:
	title_label.show_edit(intention)


func __apply_filter() -> void:
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)

	if not ctx.filter or ctx.filter.text.length() == 0:
		show()
		return

	var filter_simple := __simplify_string(ctx.filter.text)
	var title := __simplify_string(board_data.get_task(data_uuid).title)
	var description := __simplify_string(board_data.get_task(data_uuid).description)

	if (title.matchn("*" + filter_simple + "*") or (ctx.filter.advanced and description.matchn("*" + filter_simple + "*"))):
		show()
	else:
		hide()


func __simplify_string(string: String) -> String:
	return string.replace(" ", "").replace("\t", "")


func __update_context_menu():
	var shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)

	context_menu.clear()
	context_menu.add_item("Details", ACTIONS.DETAILS)

	context_menu.add_separator()

	context_menu.add_icon_item(get_theme_icon(&"Rename", &"EditorIcons"), "Rename", ACTIONS.RENAME)
	context_menu.set_item_shortcut(context_menu.get_item_index(ACTIONS.RENAME), shortcuts.rename)

	context_menu.add_icon_item(get_theme_icon(&"Duplicate", &"EditorIcons"), "Duplicate", ACTIONS.DUPLICATE)
	context_menu.set_item_shortcut(context_menu.get_item_index(ACTIONS.DUPLICATE), shortcuts.duplicate)

	context_menu.add_icon_item(get_theme_icon(&"Remove", &"EditorIcons"), "Delete", ACTIONS.DELETE)
	context_menu.set_item_shortcut(context_menu.get_item_index(ACTIONS.DELETE), shortcuts.delete)


func __action(action):
	var undo_redo: UndoRedo = __Singletons.instance_of(__EditContext, self).undo_redo

	match(action):
		ACTIONS.DELETE:
			for uuid in board_data.get_stages():
				var tasks := board_data.get_stage(uuid).tasks
				if data_uuid in tasks:
					tasks.erase(data_uuid)

					undo_redo.create_action("Delete task")
					undo_redo.add_do_property(board_data.get_stage(uuid), &"tasks", tasks)
					undo_redo.add_undo_property(board_data.get_stage(uuid), &"tasks", board_data.get_stage(uuid).tasks)
					undo_redo.commit_action()
					break

		ACTIONS.DETAILS:
			details.board_data = board_data
			details.data_uuid = data_uuid
			details.popup_centered_ratio_no_fullscreen(0.5)

		ACTIONS.DUPLICATE:
			var copy := __TaskData.new()
			copy.from_json(board_data.get_task(data_uuid).to_json())
			var copy_uuid := board_data.add_task(copy)
			for uuid in board_data.get_stages():
				var tasks := board_data.get_stage(uuid).tasks
				if data_uuid in tasks:
					tasks.insert(tasks.find(data_uuid), copy_uuid)
					undo_redo.create_action("Duplicate task")
					undo_redo.add_do_method(board_data.__add_task.bind(copy, copy_uuid))
					undo_redo.add_do_property(board_data.get_stage(uuid), &"tasks", tasks)
					undo_redo.add_undo_property(board_data.get_stage(uuid), &"tasks", board_data.get_stage(uuid).tasks)
					undo_redo.add_undo_method(board_data.remove_task.bind(copy_uuid))
					undo_redo.commit_action(false)

					board_data.get_stage(uuid).tasks = tasks
					break

		ACTIONS.RENAME:
			if context_menu.visible:
				await context_menu.popup_hide
			title_label.show_edit()


func __set_title(value: String) -> void:
	board_data.get_task(data_uuid).title = value
