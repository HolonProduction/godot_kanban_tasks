@tool
extends "kanban_resource.gd"

## Data of a task.


const __Step := preload("step.gd")

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

var steps: Array[__Step]:
	get:
		return steps.duplicate()
	set(value):
		steps = value
		changed.emit()


func _init(p_title: String = "", p_description: String = "", p_category: String = "", p_steps: Array[__Step] = []) -> void:
	title = p_title
	description = p_description
	category = p_category
	steps = p_steps
	super._init()


func to_json() -> Dictionary:
	var s: Array[Dictionary] = []
	for step in steps:
		s.append(step.to_json())

	return {
		"title": title,
		"description": description,
		"category": category,
		"steps": s,
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

	if json.has("steps"):
		var s: Array[__Step] = []
		for step in json["steps"]:
			s.append(__Step.new())
			s[-1].from_json(step)
		steps = s
	else:
		push_warning("Loading incomplete json data which is missing steps.")
