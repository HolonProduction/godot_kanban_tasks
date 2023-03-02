@tool
extends "res://addons/kanban_tasks/standalone_plugin.gd"


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __Shortcuts := preload("res://addons/kanban_tasks/view/shortcuts.gd")
const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __LayoutData := preload("res://addons/kanban_tasks/data/layout.gd")
const __TaskData := preload("res://addons/kanban_tasks/data/task.gd")
const __CategoryData := preload("res://addons/kanban_tasks/data/category.gd")
const __StageData := preload("res://addons/kanban_tasks/data/stage.gd")
const __BoardView := preload("res://addons/kanban_tasks/view/board/board.tscn")
const __BoardViewType := preload("res://addons/kanban_tasks/view/board/board.gd")
const __StartView := preload("res://addons/kanban_tasks/view/start/start.tscn")
const __StartViewType := preload("res://addons/kanban_tasks/view/start/start.gd")
const __DocumentationView := preload("res://addons/kanban_tasks/view/documentation/documentation.tscn")

const EDITOR_DATA_PATH: String = "res://addons/kanban_tasks/data.json"

enum {
	ACTION_SAVE,
	ACTION_SAVE_AS,
	ACTION_OPEN,
	ACTION_CREATE,
	ACTION_CLOSE,
	ACTION_DOCUMENTATION,
}

var main_panel_frame: MarginContainer
var start_view: __StartViewType
var file_dialog_save: FileDialog
var file_dialog_open: FileDialog
var discard_changes_dialog: ConfirmationDialog
var documentation_dialog: AcceptDialog

var file_menu: PopupMenu
var help_menu: PopupMenu

var board_view: __BoardViewType
var board_label: Label
var board_path: String = "":
	set(value):
		board_path = value
		__update_board_label()
		__update_menus()
var board_changed: bool = false:
	set(value):
		board_changed = value
		__update_board_label()


func _enter_tree() -> void:
	board_label = Label.new()
	if not Engine.is_editor_hint():
		add_control_to_container(CONTAINER_TOOLBAR, board_label)

	file_menu = PopupMenu.new()
	file_menu.name = "File"
	file_menu.add_item("Save board", ACTION_SAVE)
	file_menu.add_item("Save board as...", ACTION_SAVE_AS)
	file_menu.add_item("Close board", ACTION_CLOSE)
	file_menu.add_item("Open board...", ACTION_OPEN)
	file_menu.add_item("Create board", ACTION_CREATE)
	file_menu.id_pressed.connect(__action)
	add_menu(file_menu)

	help_menu = PopupMenu.new()
	help_menu.name = "Help"
	help_menu.add_item("Documentation", ACTION_DOCUMENTATION)
	help_menu.id_pressed.connect(__action)
	add_menu(help_menu)

	file_dialog_save = FileDialog.new()
	file_dialog_save.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog_save.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog_save.add_filter("*.kanban, *.json", "Kanban Board")
	file_dialog_save.min_size = Vector2(800, 500)
	file_dialog_save.file_selected.connect(__save_board)
	get_editor_interface().get_base_control().add_child(file_dialog_save)

	file_dialog_open = FileDialog.new()
	file_dialog_open.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog_open.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog_open.add_filter("*.kanban, *.json", "Kanban Board")
	file_dialog_open.min_size = Vector2(800, 500)
	file_dialog_open.file_selected.connect(__open_board)
	get_editor_interface().get_base_control().add_child(file_dialog_open)

	discard_changes_dialog = ConfirmationDialog.new()
	discard_changes_dialog.dialog_text = "All unsaved changes will be discarded."
	discard_changes_dialog.confirmed.connect(__close_board)
	discard_changes_dialog.unresizable = true
	get_editor_interface().get_base_control().add_child(discard_changes_dialog)

	documentation_dialog = __DocumentationView.instantiate()
	get_editor_interface().get_base_control().add_child(documentation_dialog)

	main_panel_frame = MarginContainer.new()
	main_panel_frame.add_theme_constant_override(&"margin_top", 5)
	main_panel_frame.add_theme_constant_override(&"margin_left", 5)
	main_panel_frame.add_theme_constant_override(&"margin_bottom", 5)
	main_panel_frame.add_theme_constant_override(&"margin_right", 5)
	main_panel_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_editor_interface().get_editor_main_screen().add_child(main_panel_frame)

	start_view = __StartView.instantiate()
	start_view.create_board.connect(__action.bind(ACTION_CREATE))
	start_view.open_board.connect(__action.bind(ACTION_OPEN))
	main_panel_frame.add_child(start_view)

	_make_visible(false)

	if Engine.is_editor_hint():
		if FileAccess.file_exists(EDITOR_DATA_PATH):
			__open_board(EDITOR_DATA_PATH)
		else:
			__create_board()
			__save_board(EDITOR_DATA_PATH)

	await get_tree().create_timer(0.0).timeout
	__update_menus()


func _exit_tree() -> void:
	if is_instance_valid(file_dialog_save):
		file_dialog_save.queue_free()
	if is_instance_valid(file_dialog_open):
		file_dialog_open.queue_free()
	if is_instance_valid(board_view):
		board_view.queue_free()
	if is_instance_valid(main_panel_frame):
		main_panel_frame.queue_free()


func _shortcut_input(event: InputEvent) -> void:
	var shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)
	if not Engine.is_editor_hint() and shortcuts.save.matches_event(event):
		get_viewport().set_input_as_handled()
		__action(ACTION_SAVE)

	if not Engine.is_editor_hint() and shortcuts.save_as.matches_event(event):
		get_viewport().set_input_as_handled()
		__action(ACTION_SAVE_AS)


func _has_main_screen() -> bool:
	return true


func _make_visible(visible) -> void:
	if main_panel_frame:
		main_panel_frame.visible = visible


func _get_plugin_name() -> String:
	return "Tasks"


func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/kanban_tasks/icon.svg")


func __update_menus() -> void:
	if not is_instance_valid(file_menu):
		return

	var shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)

	file_menu.set_item_disabled(
		file_menu.get_item_index(ACTION_SAVE),
		not is_instance_valid(board_view),
	)
	file_menu.set_item_shortcut(
		file_menu.get_item_index(ACTION_SAVE),
		shortcuts.save,
	)
	file_menu.set_item_disabled(
		file_menu.get_item_index(ACTION_SAVE_AS),
		not is_instance_valid(board_view),
	)
	file_menu.set_item_shortcut(
		file_menu.get_item_index(ACTION_SAVE_AS),
		shortcuts.save_as,
	)
	file_menu.set_item_disabled(
		file_menu.get_item_index(ACTION_CLOSE),
		not is_instance_valid(board_view),
	)
	file_menu.set_item_disabled(
		file_menu.get_item_index(ACTION_OPEN),
		is_instance_valid(board_view),
	)
	file_menu.set_item_disabled(
		file_menu.get_item_index(ACTION_CREATE),
		is_instance_valid(board_view),
	)


func __update_board_label() -> void:
	if not is_instance_valid(board_label):
		return
	if is_instance_valid(board_view):
		if board_path.is_empty():
			board_label.text = "unsaved"
		else:
			board_label.text = board_path
		if board_changed:
			board_label.text += "*"
	else:
		board_label.text = ""


func __action(id: int) -> void:
	match id:
		ACTION_SAVE:
			__request_save()
		ACTION_SAVE_AS:
			__request_save(true)
		ACTION_CREATE:
			__create_board()
		ACTION_OPEN:
			__request_open()
		ACTION_CLOSE:
			__request_close()
		ACTION_DOCUMENTATION:
			documentation_dialog.popup_centered()


func __request_close() -> void:
	if not board_changed:
		__close_board()
	else:
		discard_changes_dialog.popup_centered()


func __request_open() -> void:
	file_dialog_open.popup_centered()


func __request_save(force_new_location: bool = false) -> void:
	if not is_instance_valid(board_view):
		return
	if not force_new_location and not board_path.is_empty():
		__save_board(board_path)
	else:
		file_dialog_save.popup_centered()


func __create_board() -> void:
	var data := __BoardData.new()

	data.layout = __LayoutData.new([
		PackedStringArray([data.add_stage(__StageData.new("Todo"))]),
		PackedStringArray([data.add_stage(__StageData.new("Doing"))]),
		PackedStringArray([data.add_stage(__StageData.new("Done"))]),
	])
	data.add_category(
		__CategoryData.new(
			"Task",
			get_editor_interface().get_base_control().
			get_theme_color(&"accent_color", &"Editor")
		)
	)

	data.changed.connect(__on_board_changed)

	__make_board_view_visible(data)

	board_path = ""
	board_changed = false


func __save_board(path: String) -> void:
	if is_instance_valid(board_view):
		board_path = path
		board_view.board_data.save(path)
		board_changed = false


func __open_board(path: String) -> void:
	var data := __BoardData.new()
	data.load(path)
	data.changed.connect(__on_board_changed)

	__make_board_view_visible(data)

	board_path = path
	board_changed = false


func __close_board() -> void:
	board_view.queue_free()
	board_view = null
	board_path = ""
	board_changed = false
	start_view.show()


func __on_board_changed() -> void:
	board_changed = true
	if Engine.is_editor_hint():
		__request_save()


func __make_board_view_visible(data: __BoardData) -> void:
	board_view = __BoardView.instantiate()
	board_view.show_documentation.connect(__action.bind(ACTION_DOCUMENTATION))
	board_view.board_data = data

	main_panel_frame.add_child(board_view)
	start_view.hide()
