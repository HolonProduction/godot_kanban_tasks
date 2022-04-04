tool
extends Control

const task_script := preload("res://addons/kanban_tasks/task.gd")

const edit_label_script := preload("res://addons/kanban_tasks/edit_label/edit_label.gd")

onready var panel_container := $PanelContainer
onready var label_title := $PanelContainer/VBoxContainer/HBoxContainer/Title
onready var button_new := $PanelContainer/VBoxContainer/HBoxContainer/New
onready var menu_button_new := $PanelContainer/VBoxContainer/HBoxContainer/NewCategory
onready var task_holder := $PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/TaskHolder
onready var scroll_container := $PanelContainer/VBoxContainer/ScrollContainer

onready var preview_position := $PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/PreviewHolder/PreviewPosition
onready var preview_color := $PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/PreviewHolder/PreviewPosition/ColorRect

var board

var title: String setget set_title

# currently the array is filled with indexes in the init call
# but upon _ready objects get stored inside (when they where loaded)
# this behaviour results in the unusability of it before the _ready call
# this could be changed when/if godot supports parameters for 
# .instance() like it works with .new()
var tasks: Array

signal change()

func set_title(val):
	title = val
	if label_title and not label_title.text==val:
		label_title.text = val
	
	if is_inside_tree():
		emit_signal("change")

func init(board, title, tasks):
	self.board = board
	
	self.title = title
	self.tasks = tasks

func _ready():
	label_title.text = title
	label_title.connect("text_changed", self, "set_title")
	
	scroll_container.set_drag_forwarding(self)
	button_new.connect("pressed", self, "__on_add_button_pressed")
	
	menu_button_new.connect("about_to_show", self, "__on_popup_about_to_show")
	menu_button_new.get_popup().connect("id_pressed", self, "__on_category_popup_selected")
	
	board.connect("categories_changed", self, "__update_add_buttons")
	
	for t in tasks.duplicate():
		add_task(board.tasks[t], true)
		tasks.erase(t)
	
	__update_add_buttons()
	
	notification(NOTIFICATION_THEME_CHANGED)

#func mouse_exited():
	#if not Rect2(Vector2(), rect_size).has_point(get_local_mouse_position()):
#	update()

func _input(event):
	if event is InputEventMouseMotion:
		if not Rect2(Vector2(), rect_size).has_point(get_local_mouse_position()):
			preview_position.visible = false

func remove_task(task, silent = false):
	task.set_drag_forwarding(null)
	task_holder.remove_child(task)
	tasks.erase(task)
	if is_inside_tree() and not silent:
		emit_signal("change")

func add_task(task, silent=false):
	if task.is_inside_tree():
		task.get_owner().remove_task(task, silent)
	task_holder.add_child(task)
	task.set_owner(self)
	task.set_drag_forwarding(self)
	tasks.append(task)
	
	if is_inside_tree() and not silent:
		emit_signal("change")

func __update_add_buttons():
	if len(board.categories)<=1:
		button_new.visible = true
		menu_button_new.visible = false
	else:
		menu_button_new.visible = true
		button_new.visible = false

func serialize():
	var t = []
	for i in tasks:
		t.append(board.task_index(i))
	var res = {
		"title": title,
		"tasks": t
	}
	return res

func __on_add_button_pressed():
	new_task()

func new_task(category_index=0):
	var task = board.construct_task()
	task.set_category(board.categories[category_index])
	add_task(task)
	
	board.reset_filter()
	
	yield(get_tree().create_timer(0.0), "timeout")
	task.grab_focus()
	task.show_edit(edit_label_script.INTENTION.REPLACE)

func _unhandled_key_input(event):
	if not board.can_handle_shortcut(self):
		return
	
	if not event.is_echo() and event.is_pressed():
		if board.shortcut_new.is_shortcut(event):
			get_tree().set_input_as_handled()
			
			#if menu_button_new.visible:
			__on_popup_about_to_show()
			menu_button_new.get_popup().rect_position = get_global_mouse_position()
			menu_button_new.get_popup().popup()
			#else:
			#	new_task()
				
		elif board.shortcut_rename.is_shortcut(event):
			get_tree().set_input_as_handled()
			label_title.show_edit()

func can_drop_data_fw(position, data, from):
	var local_pos = (position + from.get_global_rect().position) - get_global_rect().position
	return can_drop_data(local_pos, data)
func get_drag_data_fw(position, from_control):
	if from_control is task_script:
		return from_control.get_drag_data(position)
	return null
func drop_data_fw(position, data, from):
	var local_pos = (position + from.get_global_rect().position) - get_global_rect().position
	return drop_data(local_pos, data)
	
func can_drop_data(position, data):
	preview_position.visible = true
	
	preview_position.rect_position.y = target_index_from_position(position) * (5 + 50) - 2.5
	
	if data is task_script:
		return true
	return false
func drop_data(position, data):
	var index = target_index_from_position(position)
	preview_position.visible = false
	if not data in tasks:
		add_task(data)
	#add_task_at_index(data, index)
	move_task(tasks.find_last(data), index)
	#if index == 0:
	#	move_task_between(data, null, tasks.front())
	#elif index == len(tasks):
	#	move_task_between(data, tasks.back(), null)
	#else:
	#	move_task_between()
	
	data.grab_focus()

func move_task(from: int, to: int, silent=false):
	if from < to:
		task_holder.move_child(tasks[from], to-1)
	else:
		task_holder.move_child(tasks[from], to)

	#HACK proper moving should be implemented
	tasks = task_holder.get_children()
	
	if is_inside_tree() and not silent:
		emit_signal("change")

func target_index_from_position(pos: Vector2):
	var global_pos = pos + get_global_position()
	
	if not scroll_container.get_global_rect().has_point(global_pos):
		return 0
	
	var scroll_pos = global_pos - task_holder.get_global_position()
	var c = 0
	for i in tasks:
		var y = i.rect_position.y + i.rect_size.y/2
		if scroll_pos.y < y:
			return c
		c += 1
	
	return len(tasks)

func _notification(what):
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(panel_container):
				panel_container.add_stylebox_override("panel", get_stylebox("bg", "Tree"))
			if is_instance_valid(button_new):
				button_new.icon = get_icon("Add", "EditorIcons")
			if is_instance_valid(preview_color):
				preview_color.color = get_color("font_color_fg", "Tabs")
			if is_instance_valid(menu_button_new):
				menu_button_new.icon = get_icon("Add", "EditorIcons")
				menu_button_new.add_stylebox_override("normal", get_stylebox("normal", "Button"))
				menu_button_new.add_stylebox_override("disabled", get_stylebox("disabled", "Button"))
				menu_button_new.add_stylebox_override("focus", get_stylebox("focus", "Button"))
				menu_button_new.add_stylebox_override("pressed", get_stylebox("pressed", "Button"))
				menu_button_new.add_stylebox_override("hover", get_stylebox("hover", "Button"))

func __on_category_popup_selected(id):
	new_task(id)

func __on_popup_about_to_show():
	var menu: PopupMenu = menu_button_new.get_popup()
	menu.clear()
	menu.rect_size = Vector2.ZERO
	for c in len(board.categories):
		var i = Image.new()
		i.create(16, 16, false, Image.FORMAT_RGB8)
		i.fill(board.categories[c].color)
		var t = ImageTexture.new()
		t.create_from_image(i)
		menu.add_icon_item(t, board.categories[c].title, c)
