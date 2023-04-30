@tool
extends "kanban_resource.gd"

## Data of a step.


var title: String:
	set(value):
		title = value
		changed.emit()

var done: bool:
	set(value):
		done = value
		changed.emit()


func _init(p_title: String = "", p_done: bool = true) -> void:
	title = p_title
	done = p_done
	super._init()


func to_json() -> Dictionary:
	return {
		"title": title,
		"done": done,
	}


func from_json(json: Dictionary) -> void:
	if json.has("title"):
		title = json["title"]
	else:
		push_warning("Loading incomplete json data which is missing a title.")

	if json.has("done"):
		done = json["done"]
	else:
		push_warning("Loading incomplete json data which is missing 'done'.")
