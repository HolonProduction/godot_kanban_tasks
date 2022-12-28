@tool
extends "kanban_resource.gd"

## Data of a task.


var title: String:
	set(value):
		title = value
		changed.emit()

var description: String:
	set(value):
		description = value
		changed.emit()

var category: String:
	set(value):
		category = value
		changed.emit()


func _init(p_title: String = "", p_description: String = "", p_category: String = "") -> void:
	title = p_title
	description = p_description
	category = p_category
	super._init()


func to_json() -> Dictionary:
	return {
		"title": title,
		"description": description,
		"category": category,
	}


func from_json(json: Dictionary) -> void:
	if json.has("title"):
		title = json["title"]
	else:
		push_warning("Loading incomplete json data which is missing a title.")

	if json.has("description"):
		description = json["description"]
	else:
		push_warning("Loading incomplete json data which is missing a description.")

	if json.has("category"):
		category = json["category"]
	else:
		push_warning("Loading incomplete json data which is missing a category.")
