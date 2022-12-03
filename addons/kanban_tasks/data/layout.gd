extends "kanban_resource.gd"

## Layout data.


# Use `PackedStringArray` because nested typed collections are not supported.
var columns: Array[PackedStringArray] = []:
	get:
		return columns.duplicate()
	set(value):
		columns = value
		changed.emit()


# FIXME: `p_columns` should be Array[PackedStringArray] once godot#63502 is fixed.
func _init(p_columns: Array = []) -> void:
	# Workaround for casting to typed array.
	var s: Array[PackedStringArray]
	for i in p_columns:
		s.append(i as PackedStringArray)

	columns = s

	super._init()


func to_json() -> Dictionary:
	var cols := []
	for c in columns:
		var col = []
		for uuid in c:
			col.append(uuid)
		cols.append(col)
	return {
		"columns": cols,
	}


func from_json(json: Dictionary) -> void:
	if json.has("columns"):
		if json["columns"] is Array:
			var cols: Array[PackedStringArray] = []
			for c in json["columns"]:
				var arr := PackedStringArray()
				if c is Array:
					for id in c:
						arr.append(id)
				else:
					push_warning("Layout data is corrupted.")
				cols.append(arr)
			columns = cols
		else:
			push_warning("Layout data is corrupted.")

	else:
		push_warning("Loading incomplete json data which is missing a list of columns.")

