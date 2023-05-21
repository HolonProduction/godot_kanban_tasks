@tool
extends "kanban_resource.gd"

## Contains settings that are not bound to a board.


## Whether the first line of the description is shown on the board.
var show_description_preview: bool = true:
	set(value):
		show_description_preview = value
		changed.emit()

var show_steps_preview: bool = true:
	set(value):
		show_steps_preview = value
		changed.emit()

var edit_step_details_exclusively: bool = false:
	set(value):
		edit_step_details_exclusively = value
		changed.emit()

var max_displayed_lines_in_description: int = 0:
	set(value):
		max_displayed_lines_in_description = value
		changed.emit()
		
enum DescriptionOnBoard {
	FULL,
	FIRST_LINE,
	UNTIL_FIRST_BLANK_LINE
}

var description_on_board: DescriptionOnBoard = DescriptionOnBoard.FIRST_LINE:
	set(value):
		description_on_board = value
		changed.emit()

enum StepsOnBoard {
	ONLY_OPEN,
	ALL_OPEN_FIRST,
	ALL_IN_ORDER
}

var steps_on_board: StepsOnBoard = StepsOnBoard.ONLY_OPEN:
	set(value):
		steps_on_board = value
		changed.emit()

var max_steps_on_board: int = 2:
	set(value):
		max_steps_on_board = value
		changed.emit()
		

const DEFAULT_EDITOR_DATA_PATH: String = "res://kanban_tasks_data.json"
var editor_data_file_path: String = DEFAULT_EDITOR_DATA_PATH:
	set(value):
		editor_data_file_path = value
		changed.emit()

var warn_about_empty_deletion: bool = false:
	set(value):
		warn_about_empty_deletion = value
		changed.emit()

var recent_file_count: int = 5:
	set(value):
		recent_file_count = value
		recent_files.resize(value)
		changed.emit()

var recent_files: PackedStringArray = []:
	get:
		return recent_files.duplicate()
	set(value):
		recent_files = value
		changed.emit()


func to_json() -> Dictionary:
	var res := {
		"show_description_preview": show_description_preview,
		"warn_about_empty_deletion": warn_about_empty_deletion,
		"edit_step_details_exclusively": edit_step_details_exclusively,
		"max_displayed_lines_in_description": max_displayed_lines_in_description,
		"description_on_board": description_on_board,
		"editor_data_file_path": editor_data_file_path,
	}

	if not Engine.is_editor_hint():
		res["recent_file_count"] = recent_file_count
		res["recent_files"] = recent_files

	return res


func from_json(json: Dictionary) -> void:
	if json.has("show_description_preview"):
		show_description_preview = json["show_description_preview"]
	if json.has("warn_about_empty_deletion"):
		warn_about_empty_deletion = json["warn_about_empty_deletion"]
	if json.has("edit_step_details_exclusively"):
		edit_step_details_exclusively = json["edit_step_details_exclusively"]
	if json.has("max_displayed_lines_in_description"):
		max_displayed_lines_in_description = json["max_displayed_lines_in_description"]
	if json.has("description_on_board"):
		description_on_board = json["description_on_board"]
	if json.has("editor_data_file_path"):
		editor_data_file_path = json["editor_data_file_path"]
	if json.has("recent_file_count"):
		recent_file_count = json["recent_file_count"]
	if json.has("recent_files"):
		recent_files = PackedStringArray(json["recent_files"])
