@tool
extends "res://addons/kanban_tasks/standalone_plugin.gd"

const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __TaskData := preload("res://addons/kanban_tasks/data/task.gd")
const __CategoryData := preload("res://addons/kanban_tasks/data/category.gd")
const __BoardView := preload("res://addons/kanban_tasks/view/board/board.tscn")

const main_panel := preload("res://addons/kanban_tasks/board.tscn")
var main_panel_instance


func _enter_tree():
	main_panel_instance = __BoardView.instantiate()
	var data = __BoardData.new()
	data.from_json({"categories":[{"uuid": "1610dd59-3289-4b1d-a307-5ec1b8e853ee","title": "Task","color": "6495ed"}],"stages": [{"uuid": "e96f1508-d81a-458f-bef5-c551e8485ee3","title": "Todo","tasks": ["d214f5c8-1a6e-4db1-98db-3d0294331744"]},{"uuid": "a4db015d-dcd5-4d2f-861b-e665f00208e4","title": "Doing","tasks": []},{"uuid": "8b64d1ab-9b61-4bc9-8b25-dfddccea0894","title": "Done","tasks": []}],"tasks": [{"uuid": "d214f5c8-1a6e-4db1-98db-3d0294331744","title": "Test","description": "A test task","category": "1610dd59-3289-4b1d-a307-5ec1b8e853ee"}],"layout": {"columns": [["e96f1508-d81a-458f-bef5-c551e8485ee3"],["a4db015d-dcd5-4d2f-861b-e665f00208e4"],["8b64d1ab-9b61-4bc9-8b25-dfddccea0894"]]}})
	main_panel_instance.board_data = data

	get_editor_interface().get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return "Tasks"

func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_theme_icon("EditAddRemove", "EditorIcons")
