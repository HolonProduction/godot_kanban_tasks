tool
extends Control

signal categories_changed()
signal tasks_changed()
signal stages_changed()
signal columns_changed()

const save_path := "res://addons/kanban_tasks/data.json"

const column_scene := preload("res://addons/kanban_tasks/column.tscn")
const stage_scene := preload("res://addons/kanban_tasks/stage.tscn")
const task_scene := preload("res://addons/kanban_tasks/task.tscn")

var columns = []
var stages = []
var tasks = []
var categories = []

var shortcut_delete := ShortCut.new()
var shortcut_duplicate := ShortCut.new()
var shortcut_new := ShortCut.new()
var shortcut_rename := ShortCut.new()
var shortcut_search := ShortCut.new()
var shortcut_confirm := ShortCut.new()

onready var search_bar: LineEdit = $Header/HBoxContainer/Search
onready var button_search_details: Button = $Header/HBoxContainer/SearchDetails
onready var button_settings: Button = $Header/HBoxContainer/Settings
onready var button_help: Button = $Header/HBoxContainer/Help
onready var column_holder: HBoxContainer = $MarginContainer/ScrollContainer/Columns

onready var details_dialog := $Dialogs/Details
onready var documentation_dialog := $Dialogs/Documentation
onready var settings_dialog := $Dialogs/Settings

class Category:
	signal changed()
	var title: String setget set_title
	var color: Color setget set_color
	func set_title(val):
		title = val
		emit_signal("changed")
	func set_color(val):
		color = val
		emit_signal("changed")
	
	func _init(title: String, color: Color):
		self.title = title
		self.color = color
	func serialize()->Dictionary:
		return {
			"title": title,
			"color": color.to_html(false),
		}

func setup_shortcuts():
	# delete
	var delete = InputEventKey.new()
	if OS.get_name() == "OSX":
		delete.scancode = KEY_BACKSPACE
		delete.command = true
	else:
		delete.scancode = KEY_DELETE
	shortcut_delete.shortcut = delete
	
	# duplicate
	var dupe = InputEventKey.new()
	if OS.get_name() == "OSX":
		dupe.scancode = KEY_D
		dupe.command = true
	else:
		dupe.scancode = KEY_D
		dupe.control = true
	shortcut_duplicate.shortcut = dupe
	
	# new
	var new = InputEventKey.new()
	if OS.get_name() == "OSX":
		new.scancode = KEY_A
		new.command = true
	else:
		new.scancode = KEY_A
		new.control = true
	shortcut_new.shortcut = new
	
	# rename
	var rename = InputEventKey.new()
	rename.scancode = KEY_F2
	shortcut_rename.shortcut = rename
	
	# search
	var search = InputEventKey.new()
	if OS.get_name() == "OSX":
		search.scancode = KEY_F
		search.command = true
	else:
		search.scancode = KEY_F
		search.control = true
	shortcut_search.shortcut = search
	
	# confirm
	var confirm = InputEventKey.new()
	confirm.scancode = KEY_ENTER
	shortcut_confirm.shortcut = confirm
	

func _ready():
	setup_shortcuts()
	setup_board()
	
	search_bar.connect("text_changed", self, "__on_filter_changed")
	search_bar.connect("text_entered", self, "__on_filter_entered")
	button_search_details.connect("toggled", self, "__on_filter_changed")
	button_help.connect("pressed", self, "__on_documentation_button_clicked")
	button_settings.connect("pressed", self, "__on_settings_button_clicked")
	
	connect("categories_changed", self, "save_data")
	connect("tasks_changed", self, "save_data")
	connect("columns_changed", self, "save_data")
	connect("stages_changed", self, "save_data")
	
	notification(NOTIFICATION_THEME_CHANGED)

func get_details_dialog():
	return details_dialog

func construct_category(title: String, color: Color):
	var cat = Category.new(title, color)
	categories.append(cat)
	cat.connect("changed", self, "save_data")
	emit_signal("categories_changed")
	return cat
func category_index(cat, unsafe = false):
	if not unsafe:
		assert(cat in categories, "You have to construct categories by using the board.")
	return categories.find(cat)
func delete_category(cat):
	categories.erase(cat)
	emit_signal("categories_changed")

func _unhandled_key_input(event):
	if not can_handle_shortcut(self):
		return
		
	if not event.is_echo() and event.is_pressed() and shortcut_search.is_shortcut(event):
		search_bar.grab_focus()
		get_tree().set_input_as_handled()

func construct_task(title:String="Task", details:String="", category=categories[0]):
	var scene = task_scene.instance()
	scene.connect("change", self, "save_data")
	tasks.append(scene)
	scene.init(self, title, details, category)
	emit_signal("tasks_changed")
	return scene
func task_index(task, unsafe = false):
	if not unsafe:
		assert(task in tasks, "You have to construct tasks by using the board.")
	return tasks.find(task)
func delete_task(scene):
	if scene.is_inside_tree():
		scene.get_owner().remove_task(scene)
	tasks.erase(scene)
	scene.queue_free()
	emit_signal("tasks_changed")

func construct_stage(title:String="Stage", tasks:Array=[]):
	var scene = stage_scene.instance()
	scene.connect("change", self, "save_data")
	stages.append(scene)
	scene.init(self, title, tasks)
	emit_signal("stages_changed")
	return scene
func stage_index(stage, unsafe = false):
	if not unsafe:
		assert(stage in stages, "You have to construct stages by using the board.")
	return stages.find(stage)
func delete_stage(scene):
	if scene.is_inside_tree():
		scene.get_owner().remove_stage(scene)
	stages.erase(scene)
	scene.queue_free()
	emit_signal("stages_changed")

func construct_column(stages:Array=[]):
	var scene = column_scene.instance()
	scene.connect("change", self, "save_data")
	columns.append(scene)
	scene.init(self, stages)
	emit_signal("columns_changed")
	return scene
func column_index(column, unsafe = false):
	if not unsafe:
		assert(column in columns, "You have to construct columns by using the board.")
	return columns.find(column)
func delete_column(scene):
	if scene.is_inside_tree():
		scene.get_owner().remove_column(scene)
	columns.erase(scene)
	scene.queue_free()
	emit_signal("columns_changed")

func can_handle_shortcut(node):
	return get_focus_owner() and (node.is_a_parent_of(get_focus_owner()) or get_focus_owner()==node)

func clear_board():
	for c in column_holder.get_children():
		c.queue_free()
	columns = []
	stages = []
	categories = []
	emit_signal("categories_changed")
	emit_signal("columns_changed")
	emit_signal("stages_changed")
	emit_signal("tasks_changed")

func load_data()->Dictionary:
	var file := File.new()
	var res = file.open(save_path, File.READ)
	if res != OK:
		return default_data()
	
	res = JSON.parse(file.get_as_text())
	if res.error != OK:
		return default_data()
	file.close()
	
	res = res.result
	
	for category in res["categories"]:
		category["color"] = Color(category["color"])
	
	for task in res["tasks"]:
		task["category"] = int(task["category"])
	
	for stage in res["stages"]:
		var tasks_i = []
		for t in stage["tasks"]:
			tasks_i.append(int(t))
		stage["tasks"] = tasks_i
	
	for column in res["columns"]:
		var stages_i = []
		for t in column["stages"]:
			stages_i.append(int(t))
		column["stages"] = stages_i
		
	
	return res

func default_data():
	return {
		"columns": [
			{
				"stages": [0],
			},
			{
				"stages": [1],
			},
			{
				"stages": [2],
			},
		],
		"stages": [
			{
				"title": "Todo",
				"tasks": [],
			},
			{
				"title": "Doing",
				"tasks": [],
			},
			{
				"title": "Done",
				"tasks": [],
			},
		],
		"tasks": [],
		"categories": [
			{"title": "Task", "color": Color.cornflower}
		],
	}

func serialze():
	var res = {
		"categories": [],
		"columns": [],
		"stages": [],
		"tasks": [],
	}
	for category in categories:
		res["categories"].append(category.serialize())
	for column in columns:
		res["columns"].append(column.serialize())
	for stage in stages:
		res["stages"].append(stage.serialize())
	for task in tasks:
		res["tasks"].append(task.serialize())
	return res

func save_data():
	var data = serialze()
	
	var file := File.new()
	var res = file.open(save_path, File.WRITE)
	if res != OK:
		push_warning("Could not save board data.")
	
	var string = JSON.print(data, "  ")
	
	file.store_string(string)
	file.close()

func setup_board():
	clear_board()
	var data = load_data()
	
	for c in data["categories"]:
		construct_category(c["title"],
				c["color"])
	
	for t in data["tasks"]:
		construct_task(
			t["title"],
			t["details"],
			categories[t["category"]])
		
	for s in data["stages"]:
		construct_stage(
			s["title"],
			s["tasks"])
		
	for c in data["columns"]:
		var column = construct_column(c["stages"])
		column_holder.add_child(column)
	
	emit_signal("categories_changed")
	emit_signal("columns_changed")
	emit_signal("stages_changed")
	emit_signal("tasks_changed")
		
func _notification(what):
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(search_bar):
				search_bar.right_icon = get_icon("Search", "EditorIcons")
			if is_instance_valid(button_settings):
				button_settings.icon = get_icon("Tools", "EditorIcons")
			if is_instance_valid(button_help):
				button_help.icon = get_icon("Help", "EditorIcons")
			if is_instance_valid(button_search_details):
				button_search_details.icon = get_icon("MultiLine", "EditorIcons")

func reset_filter():
	search_bar.text = ""
	__update_filter()

func show_documentation():
	documentation_dialog.popup_centered()

func show_settings():
	settings_dialog.popup_centered()

func __update_filter():
	for t in tasks:
		t.apply_filter(search_bar.text, button_search_details.pressed)

# do not use parameters
# method is bound to diffrent signals
func __on_filter_changed(param1=null):
	__update_filter()

func __on_filter_entered(filter):
	button_search_details.grab_focus()

func __on_documentation_button_clicked():
	show_documentation()

func __on_settings_button_clicked():
	show_settings()
