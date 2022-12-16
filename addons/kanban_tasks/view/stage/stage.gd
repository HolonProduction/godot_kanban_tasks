@tool
extends MarginContainer

## The visual representation of a stage.


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __Shortcuts := preload("res://addons/kanban_tasks/view/shortcuts.gd")
const __TaskScene := preload("res://addons/kanban_tasks/view/task/task.tscn")
const __TaskScript := preload("res://addons/kanban_tasks/view/task/task.gd")
const __EditLabel := preload("res://addons/kanban_tasks/edit_label/edit_label.gd")
const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")

var board_data: __BoardData
var data_uuid: String

# The uuid of the task that should get focus.
var __old_focus: String

@onready var panel_container: PanelContainer = %Panel
@onready var title_label: __EditLabel = %Title
@onready var create_button: Button = %Create
@onready var create_menu_button: MenuButton = %CreateMenu
@onready var task_holder: VBoxContainer = %TaskHolder
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var preview: Control = %Preview
@onready var preview_color: ColorRect = %Preview/Color


func _ready() -> void:
	update()
	board_data.get_stage(data_uuid).changed.connect(update)

	scroll_container.set_drag_forwarding(self)

	create_button.pressed.connect(__on_add_button_pressed)
	create_menu_button.about_to_popup.connect(__on_popup_about_to_show)
	create_menu_button.get_popup().id_pressed.connect(__on_category_popup_selected)

	__update_add_buttons()

	notification(NOTIFICATION_THEME_CHANGED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
			preview.visible = false


func _shortcut_input(event: InputEvent) -> void:
	if not __Shortcuts.should_handle_shortcut(self):
		return
	var __shortcuts: __Shortcuts = __Singletons.instance_of(__Shortcuts, self)
	if not event.is_echo() and event.is_pressed():
		if __shortcuts.create.matches_event(event):
			get_viewport().set_input_as_handled()

			__on_popup_about_to_show()
			create_menu_button.get_popup().position = get_global_mouse_position()
			if not get_viewport().gui_embed_subwindows and get_viewport() is Window:
				create_menu_button.get_popup().position += get_viewport().position

			create_menu_button.get_popup().popup()

		elif __shortcuts.rename.matches_event(event):
			get_viewport().set_input_as_handled()
			title_label.show_edit()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	preview.visible = true
	preview.position.y = __target_height_from_position(at_position)

	return data is Dictionary and data.has("task") and data.has("stage")


func _can_drop_data_fw(at_position: Vector2, data: Variant, from: Control) -> bool:
	var local_pos = (at_position + from.get_global_rect().position) - get_global_rect().position
	return _can_drop_data(local_pos, data)


func _get_drag_data_fw(at_position: Vector2, from: Control) -> Variant:
	if from is __TaskScript:
		var control := Control.new()
		var rect := ColorRect.new()
		control.add_child(rect)
		rect.size = from.get_rect().size
		rect.position = -at_position
		rect.color = board_data.get_category(board_data.get_task(from.data_uuid).category).color
		from.set_drag_preview(control)

		return {
			"task": from.data_uuid,
			"stage": data_uuid,
		}
	return null


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var index := __target_index_from_position(at_position)
	preview.hide()

	var tasks := board_data.get_stage(data["stage"]).tasks

	if data["stage"] == data_uuid:
		var old_index := tasks.find(data["task"])
		if index < old_index:
			tasks.erase(data["task"])
			tasks.insert(index, data["task"])
		elif index > old_index + 1:
			tasks.erase(data["task"])
			tasks.insert(index - 1, data["task"])
	else:
		tasks.erase(data["task"])
		board_data.get_stage(data["stage"]).tasks = tasks
		tasks = board_data.get_stage(data_uuid).tasks
		tasks.insert(index, data["task"])

	__old_focus = data["task"]
	board_data.get_stage(data_uuid).tasks = tasks


func _drop_data_fw(at_position: Vector2, data: Variant, from: Control) -> void:
	var local_pos = (at_position + from.get_global_rect().position) - get_global_rect().position
	return _drop_data(local_pos, data)


func _notification(what: int) -> void:
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(panel_container):
				panel_container.add_theme_stylebox_override(&"panel", get_theme_stylebox(&"panel", &"Tree"))
			if is_instance_valid(create_button):
				create_button.icon = get_theme_icon(&"Add", &"EditorIcons")
			if is_instance_valid(preview_color):
				preview_color.color = get_theme_color(&"font_selected_color", &"TabBar")
			if is_instance_valid(create_menu_button):
				create_menu_button.icon = get_theme_icon(&"Add", &"EditorIcons")
				create_menu_button.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"normal", &"Button"))
				create_menu_button.add_theme_stylebox_override(&"disabled", get_theme_stylebox(&"disabled", &"Button"))
				create_menu_button.add_theme_stylebox_override(&"focus", get_theme_stylebox(&"focus", &"Button"))
				create_menu_button.add_theme_stylebox_override(&"pressed", get_theme_stylebox(&"pressed", &"Button"))
				create_menu_button.add_theme_stylebox_override(&"hover", get_theme_stylebox(&"hover", &"Button"))


func update() -> void:
	if title_label.text_changed.is_connected(__set_title):
		title_label.text_changed.disconnect(__set_title)
	title_label.text = board_data.get_stage(data_uuid).title
	title_label.text_changed.connect(__set_title)

	var old_scroll := scroll_container.scroll_vertical

	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner) and is_ancestor_of(focus_owner):
		if focus_owner is __TaskScript:
			__old_focus = focus_owner.data_uuid

	for task in task_holder.get_children():
		task.queue_free()

	for uuid in board_data.get_stage(data_uuid).tasks:
		var task = __TaskScene.instantiate()
		task.board_data = board_data
		task.data_uuid = uuid
		task.set_drag_forwarding(self)
		task_holder.add_child(task)
		if uuid == __old_focus:
			__old_focus = ""

			# Use a lambda to not stop further processing while awaiting.
			var lambda = func():
				await get_tree().create_timer(0.0).timeout
				task.grab_focus()
			lambda.call()

	scroll_container.scroll_vertical = old_scroll


func __target_index_from_position(pos: Vector2) -> int:
	var global_pos := pos + get_global_position()

	if not scroll_container.get_global_rect().has_point(global_pos):
		return 0

	var scroll_pos := global_pos - task_holder.get_global_position()
	var c := 0
	for task in task_holder.get_children():
		var y = task.position.y + task.size.y/2
		if scroll_pos.y < y:
			return c
		c += 1

	return task_holder.get_child_count()


func __set_title(value: String) -> void:
	board_data.get_stage(data_uuid).title = value


func __update_add_buttons() -> void:
	if board_data.get_category_count() <= 1:
		create_button.show()
		create_menu_button.hide()
	else:
		create_menu_button.show()
		create_button.hide()


func __on_add_button_pressed() -> void:
	__create_task()


func __create_task() -> void:
	pass

#func new_task(category_index=0):
#	var task = board.construct_task()
#	task.category = board.categories[category_index]
#	add_task(task)

#	board.reset_filter()

#	await get_tree().create_timer(0.0).timeout
#	task.grab_focus()
#	task.show_edit(edit_label_script.INTENTION.REPLACE)


func __target_height_from_position(pos: Vector2) -> float:
	var global_pos = pos + get_global_position()

	if not scroll_container.get_global_rect().has_point(global_pos):
		return - float(task_holder.get_theme_constant(&"separation")) / 2.0

	var scroll_pos := global_pos - task_holder.get_global_position()
	var c := 0.0
	for task in task_holder.get_children():
		var y = task.position.y + task.size.y/2.0
		if scroll_pos.y < y:
			return c - float(task_holder.get_theme_constant(&"separation")) / 2.0
		c += task.size.y + task_holder.get_theme_constant(&"separation")

	return c


func __on_category_popup_selected(id):
	#new_task(id)
	pass


func __on_popup_about_to_show():
	var menu: PopupMenu = create_menu_button.get_popup()
	menu.clear()
	#menu.size = Vector2.ZERO
	for uuid in board_data.get_categories():
		var i = Image.create(16, 16, false, Image.FORMAT_RGB8)
		i.fill(board_data.get_category(uuid).color)
		var t = ImageTexture.create_from_image(i)
		menu.add_icon_item(t, board_data.get_category(uuid).title)
		menu.set_item_metadata(-1, uuid)
