@tool
extends VBoxContainer

## The visual representation of a kanban board.


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __Shortcuts := preload("res://addons/kanban_tasks/view/shortcuts.gd")
const __EditContext := preload("res://addons/kanban_tasks/view/edit_context.gd")
const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __StageScript := preload("res://addons/kanban_tasks/view/stage/stage.gd")
const __StageScene := preload("res://addons/kanban_tasks/view/stage/stage.tscn")
const __TaskScript := preload("res://addons/kanban_tasks/view/task/task.gd")
const __TaskScene := preload("res://addons/kanban_tasks/view/task/task.tscn")
const __Filter := preload("res://addons/kanban_tasks/view/filter.gd")
const __SettingsScript := preload("res://addons/kanban_tasks/view/settings/settings.gd")

signal show_documentation()

var board_data: __BoardData

@onready var search_bar: LineEdit = %SearchBar
@onready var button_advanced_search: Button = %AdvancedSearch
@onready var button_show_categories: Button = %ShowCategories
@onready var button_show_descriptions: Button = %ShowDescriptions
@onready var button_show_steps: Button = %ShowSteps
@onready var button_documentation: Button = %Documentation
@onready var button_settings: Button = %Settings
@onready var column_holder: HBoxContainer = %ColumnHolder
@onready var settings: __SettingsScript = %SettingsView

var stage_views_per_uuid = {}
var task_views_per_uuid = {}


func _ready():
	update()
	board_data.layout.changed.connect(update)

	settings.board_data = board_data

	search_bar.text_changed.connect(__on_filter_changed)
	search_bar.text_submitted.connect(__on_search_bar_entered)
	button_advanced_search.toggled.connect(__on_filter_changed)

	button_show_categories.toggled.connect(__on_show_categories_toggled)
	button_show_descriptions.toggled.connect(__on_show_descriptions_toggled)
	button_show_steps.toggled.connect(__on_show_steps_toggled)

	notification(NOTIFICATION_THEME_CHANGED)

	await get_tree().create_timer(0.0).timeout
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)

	ctx.settings.changed.connect(update)

	ctx.filter_changed.connect(__on_filter_changed_external)

	button_documentation.pressed.connect(func(): show_documentation.emit())
	button_documentation.visible = Engine.is_editor_hint()

	button_settings.pressed.connect(settings.popup_centered_ratio_no_fullscreen)


func _shortcut_input(event: InputEvent) -> void:
	if not __Shortcuts.should_handle_shortcut(self):
		return
	var shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	if not event.is_echo() and event.is_pressed():
		if shortcuts.search.matches_event(event):
			search_bar.grab_focus()
			get_viewport().set_input_as_handled()
		elif shortcuts.undo.matches_event(event):
			ctx.undo_redo.undo()
			get_viewport().set_input_as_handled()
		elif shortcuts.redo.matches_event(event):
			ctx.undo_redo.redo()
			get_viewport().set_input_as_handled()


func _notification(what):
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(search_bar):
				search_bar.right_icon = get_theme_icon(&"Search", &"EditorIcons")
			if is_instance_valid(button_settings):
				button_settings.icon = get_theme_icon(&"Tools", &"EditorIcons")
			if is_instance_valid(button_documentation):
				button_documentation.icon = get_theme_icon(&"Help", &"EditorIcons")
			if is_instance_valid(button_advanced_search):
				button_advanced_search.icon = get_theme_icon(&"Zoom", &"EditorIcons")
			if is_instance_valid(button_show_categories):
				button_show_categories.icon = get_theme_icon(&"Rectangle", &"EditorIcons")
			if is_instance_valid(button_show_descriptions):
				button_show_descriptions.icon = get_theme_icon(&"Script", &"EditorIcons")
			if is_instance_valid(button_show_steps):
				button_show_steps.icon = get_theme_icon(&"FileList", &"EditorIcons")


func update() -> void:
	for column in column_holder.get_children():
		column.queue_free()

	for column_data in board_data.layout.columns:
		var column_scroll = ScrollContainer.new()
		column_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		column_scroll.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		column_scroll.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		var column = VBoxContainer.new()
		column.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		column.set_h_size_flags(Control.SIZE_EXPAND_FILL)

		column_scroll.add_child(column)
		column_holder.add_child(column_scroll)

		for uuid in column_data:
			var stage := get_stage_view_per_uuid(uuid)
			stage.board_data = board_data
			stage.data_uuid = uuid
			if stage.get_parent() != null:
				stage.get_parent().remove_child(stage)
			column.add_child(stage)

	__clean_up_stage_and_task_view_dict()

	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	button_show_categories.set_pressed_no_signal(ctx.settings.show_category_on_board)
	button_show_descriptions.set_pressed_no_signal(ctx.settings.show_description_preview)
	button_show_steps.set_pressed_no_signal(ctx.settings.show_steps_preview)


func get_stage_view_per_uuid(uuid: String) -> __StageScript:
	var stage_view: __StageScript
	if stage_views_per_uuid.has(uuid):
		stage_view = stage_views_per_uuid[uuid]
	else:
		stage_view = __StageScene.instantiate()
		stage_view.parent_board_view = self
		stage_views_per_uuid[uuid] = stage_view
	return stage_view


func get_task_view_per_uuid(uuid: String) -> __TaskScript:
	var task_view: __TaskScript
	if task_views_per_uuid.has(uuid):
		task_view = task_views_per_uuid[uuid]
	else:
		task_view = __TaskScene.instantiate()
		task_views_per_uuid[uuid] = task_view
	return task_view


func __clean_up_stage_and_task_view_dict() -> void:
	var stages_on_board := PackedStringArray()
	for column_data in board_data.layout.columns:
		for uuid in column_data:
			stages_on_board.append(uuid)
	for uuid in stage_views_per_uuid:
		if not uuid in stages_on_board:
			stage_views_per_uuid[uuid].queue_free()
			stage_views_per_uuid.erase(uuid)
	var tasks_on_board := PackedStringArray()
	for uuid in stages_on_board:
		tasks_on_board.append_array(board_data.get_stage(uuid).tasks)
	for uuid in task_views_per_uuid:
		if not uuid in tasks_on_board:
			task_views_per_uuid[uuid].queue_free()
			task_views_per_uuid.erase(uuid)


# Do not use parameters the method is bound to diffrent signals.
func __on_filter_changed(param1: Variant = null):
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)

	if ctx.filter_changed.is_connected(__on_filter_changed_external):
		ctx.filter_changed.disconnect(__on_filter_changed_external)

	ctx.filter = __Filter.new(search_bar.text, button_advanced_search.button_pressed)

	ctx.filter_changed.connect(__on_filter_changed_external)


func __on_search_bar_entered(filter: String):
	button_advanced_search.grab_focus()


func __on_filter_changed_external():
	search_bar.text = ""


func __on_show_categories_toggled(button_pressed: bool):
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	ctx.settings.show_category_on_board = button_pressed


func __on_show_descriptions_toggled(button_pressed: bool):
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	ctx.settings.show_description_preview = button_pressed


func __on_show_steps_toggled(button_pressed: bool):
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	ctx.settings.show_steps_preview = button_pressed
