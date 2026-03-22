@tool
extends RefCounted

## Validates serialized kanban board files before disk content replaces the
## current live board in memory.
##
## This is used by strict load/reload paths to reject malformed, partial, or
## structurally invalid board data instead of best-effort loading it and
## potentially destroying the currently open board state.
## This is especially important when external tools or agents edit `.kanban`
## files directly, because the plugin can observe intermediate writes or
## malformed output while those edits are in progress.
##
## Supports both the current board file format and the legacy format that still
## uses top-level `columns`.

## Validates the loaded json for either the current or legacy board format.
static func validate_loaded_json(data: Dictionary) -> String:
	var is_legacy_format := data.has("columns")
	if is_legacy_format:
		return __validate_legacy_board_json(data)

	return __validate_current_board_json(data)


## Validates a board serialized in the legacy file format.
static func __validate_legacy_board_json(json: Dictionary) -> String:
	var board_section_error := __validate_legacy_board_sections(json)
	if not board_section_error.is_empty():
		return board_section_error

	var category_error := __validate_legacy_categories(json["categories"])
	if not category_error.is_empty():
		return category_error

	var task_error := __validate_legacy_tasks(json["tasks"], json["categories"].size())
	if not task_error.is_empty():
		return task_error

	var stage_error := __validate_legacy_stages(json["stages"], json["tasks"].size())
	if not stage_error.is_empty():
		return stage_error

	return __validate_legacy_columns(json["columns"], json["stages"].size())


## Validates a board serialized in the current file format.
static func __validate_current_board_json(json: Dictionary) -> String:
	var board_section_error := __validate_current_board_sections(json)
	if not board_section_error.is_empty():
		return board_section_error

	var category_ids := {}
	var category_error := __validate_current_categories(json["categories"], category_ids)
	if not category_error.is_empty():
		return category_error

	var task_ids := {}
	var task_error := __validate_current_tasks(
		json["tasks"],
		category_ids,
		task_ids,
	)
	if not task_error.is_empty():
		return task_error

	var stage_ids := {}
	var stage_error := __validate_current_stages(json["stages"], task_ids, stage_ids)
	if not stage_error.is_empty():
		return stage_error

	return __validate_current_layout(json["layout"], stage_ids)


## Checks that all required top-level sections exist for the current format.
static func __validate_current_board_sections(json: Dictionary) -> String:
	if not (json.get("categories", null) is Array):
		return "it is missing the categories array."

	if not (json.get("stages", null) is Array):
		return "it is missing the stages array."

	if not (json.get("tasks", null) is Array):
		return "it is missing the tasks array."

	if not (json.get("layout", null) is Dictionary):
		return "it is missing the layout object."

	return ""


## Validates current-format categories and collects their UUIDs.
static func __validate_current_categories(categories: Array, category_ids: Dictionary) -> String:
	for index in range(categories.size()):
		var category = categories[index]

		if not (category is Dictionary):
			return "category entry " + str(index) + " is not an object."

		var category_uuid = category.get("uuid", null)

		if not (category_uuid is String) or category_uuid.is_empty():
			return "category entry " + str(index) + " is missing a uuid."

		if category_ids.has(category_uuid):
			return "category uuid " + category_uuid + " is duplicated."

		if not (category.get("title", null) is String):
			return "category " + category_uuid + " is missing a title."

		if not (category.get("color", null) is String):
			return "category " + category_uuid + " is missing a color."

		category_ids[category_uuid] = true

	return ""


## Validates current-format tasks and collects their UUIDs.
static func __validate_current_tasks(
	tasks: Array,
	category_ids: Dictionary,
	task_ids: Dictionary,
) -> String:
	for index in range(tasks.size()):
		var task = tasks[index]
		if not (task is Dictionary):
			return "task entry " + str(index) + " is not an object."

		var task_uuid = task.get("uuid", null)
		if not (task_uuid is String) or task_uuid.is_empty():
			return "task entry " + str(index) + " is missing a uuid."

		if task_ids.has(task_uuid):
			return "task uuid " + task_uuid + " is duplicated."

		var task_error := __validate_current_task(task, task_uuid, category_ids)
		if not task_error.is_empty():
			return task_error

		task_ids[task_uuid] = true

	return ""


## Validates one current-format task entry.
static func __validate_current_task(
	task: Dictionary,
	task_uuid: String,
	category_ids: Dictionary,
) -> String:
	if not (task.get("title", null) is String):
		return "task " + task_uuid + " is missing a title."

	if not (task.get("description", null) is String):
		return "task " + task_uuid + " is missing a description."

	var category_uuid = task.get("category", null)
	if not (category_uuid is String) or not category_ids.has(category_uuid):
		return "task " + task_uuid + " references a missing category."

	if not (task.get("steps", null) is Array):
		return "task " + task_uuid + " is missing the steps array."

	return __validate_current_task_steps(task["steps"], task_uuid)


## Validates the steps list of one current-format task entry.
static func __validate_current_task_steps(steps: Array, task_uuid: String) -> String:
	for step in steps:
		if not (step is Dictionary):
			return "task " + task_uuid + " has a step that is not an object."

		if not (step.get("details", null) is String):
			return "task " + task_uuid + " has a step without details."

		if not (step.get("done", null) is bool):
			return "task " + task_uuid + " has a step without a done flag."

	return ""


## Validates current-format stages and collects their UUIDs.
static func __validate_current_stages(
	stages: Array,
	task_ids: Dictionary,
	stage_ids: Dictionary,
) -> String:
	for index in range(stages.size()):
		var stage = stages[index]
		if not (stage is Dictionary):
			return "stage entry " + str(index) + " is not an object."

		var stage_uuid = stage.get("uuid", null)
		if not (stage_uuid is String) or stage_uuid.is_empty():
			return "stage entry " + str(index) + " is missing a uuid."

		if stage_ids.has(stage_uuid):
			return "stage uuid " + stage_uuid + " is duplicated."

		var stage_error := __validate_current_stage(stage, stage_uuid, task_ids)
		if not stage_error.is_empty():
			return stage_error

		stage_ids[stage_uuid] = true

	return ""


## Validates one current-format stage entry.
static func __validate_current_stage(
	stage: Dictionary,
	stage_uuid: String,
	task_ids: Dictionary,
) -> String:
	if not (stage.get("title", null) is String):
		return "stage " + stage_uuid + " is missing a title."

	if not (stage.get("tasks", null) is Array):
		return "stage " + stage_uuid + " is missing the tasks array."

	for task_uuid in stage["tasks"]:
		if not (task_uuid is String) or not task_ids.has(task_uuid):
			return "stage " + stage_uuid + " references a missing task."

	return ""


## Validates the layout section of the current file format.
static func __validate_current_layout(layout: Dictionary, stage_ids: Dictionary) -> String:
	if not (layout.get("columns", null) is Array):
		return "layout is missing the columns array."

	for column_index in range(layout["columns"].size()):
		var column = layout["columns"][column_index]
		if not (column is Array):
			return "layout column " + str(column_index) + " is not an array."

		for stage_uuid in column:
			if not (stage_uuid is String) or not stage_ids.has(stage_uuid):
				return "layout column " + str(column_index) + " references a missing stage."

	return ""


## Checks that all required top-level sections exist for the legacy format.
static func __validate_legacy_board_sections(json: Dictionary) -> String:
	if not (json.get("categories", null) is Array):
		return "the legacy board is missing the categories array."

	if not (json.get("tasks", null) is Array):
		return "the legacy board is missing the tasks array."

	if not (json.get("stages", null) is Array):
		return "the legacy board is missing the stages array."

	if not (json.get("columns", null) is Array):
		return "the legacy board is missing the columns array."

	return ""


## Validates legacy-format category entries.
static func __validate_legacy_categories(categories: Array) -> String:
	for index in range(categories.size()):
		var category = categories[index]
		if not (category is Dictionary):
			return "legacy category entry " + str(index) + " is not an object."

		if not (category.get("title", null) is String):
			return "legacy category entry " + str(index) + " is missing a title."

		if not (category.get("color", null) is String):
			return "legacy category entry " + str(index) + " is missing a color."

	return ""


## Validates legacy-format task entries.
static func __validate_legacy_tasks(tasks: Array, category_count: int) -> String:
	for index in range(tasks.size()):
		var task = tasks[index]
		if not (task is Dictionary):
			return "legacy task entry " + str(index) + " is not an object."

		if not (task.get("title", null) is String):
			return "legacy task entry " + str(index) + " is missing a title."

		if not (task.get("details", null) is String):
			return "legacy task entry " + str(index) + " is missing details."

		if not __is_valid_legacy_index(task.get("category", null), category_count):
			return "legacy task entry " + str(index) + " references an invalid category."

	return ""


## Validates legacy-format stage entries.
static func __validate_legacy_stages(stages: Array, task_count: int) -> String:
	for index in range(stages.size()):
		var stage = stages[index]
		if not (stage is Dictionary):
			return "legacy stage entry " + str(index) + " is not an object."

		if not (stage.get("title", null) is String):
			return "legacy stage entry " + str(index) + " is missing a title."

		if not (stage.get("tasks", null) is Array):
			return "legacy stage entry " + str(index) + " is missing the tasks array."

		for task_index in stage["tasks"]:
			if not __is_valid_legacy_index(task_index, task_count):
				return "legacy stage entry " + str(index) + " references an invalid task."

	return ""


## Validates legacy-format column entries.
static func __validate_legacy_columns(columns: Array, stage_count: int) -> String:
	for index in range(columns.size()):
		var column = columns[index]
		if not (column is Dictionary):
			return "legacy column entry " + str(index) + " is not an object."

		if not (column.get("stages", null) is Array):
			return "legacy column entry " + str(index) + " is missing the stages array."

		for stage_index in column["stages"]:
			if not __is_valid_legacy_index(stage_index, stage_count):
				return "legacy column entry " + str(index) + " references an invalid stage."

	return ""


## Returns whether a legacy index points to an entry inside the target array bounds.
static func __is_valid_legacy_index(value: Variant, size: int) -> bool:
	if value is int:
		return value >= 0 and value < size

	if value is float:
		var index := int(value)
		return is_equal_approx(value, index) and index >= 0 and index < size

	return false
