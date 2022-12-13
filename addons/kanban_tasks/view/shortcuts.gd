extends Node


var delete := Shortcut.new()
var duplicate := Shortcut.new()
var create := Shortcut.new()
var rename := Shortcut.new()
var search := Shortcut.new()
var confirm := Shortcut.new()


## Returns whether a specific node should handle the shortcut.
static func should_handle_shortcut(node: Node) -> bool:
	var focus_owner := node.get_viewport().gui_get_focus_owner()
	return focus_owner and (node.is_ancestor_of(focus_owner) or focus_owner == node)


func _ready() -> void:
	__setup_shortcuts()


func __setup_shortcuts() -> void:
	# delete
	var ev_delete = InputEventKey.new()
	if OS.get_name() == "OSX":
		ev_delete.keycode = KEY_BACKSPACE
		ev_delete.command = true
	else:
		ev_delete.keycode = KEY_DELETE
	delete.events.append(ev_delete)

	# duplicate
	var ev_dupe = InputEventKey.new()
	if OS.get_name() == "OSX":
		ev_dupe.keycode = KEY_D
		ev_dupe.command = true
	else:
		ev_dupe.keycode = KEY_D
		ev_dupe.ctrl_pressed = true
	duplicate.events.append(ev_dupe)

	# create
	var ev_create = InputEventKey.new()
	if OS.get_name() == "OSX":
		ev_create.keycode = KEY_A
		ev_create.command = true
	else:
		ev_create.keycode = KEY_A
		ev_create.ctrl_pressed = true
	create.events.append(ev_create)

	# rename
	var ev_rename = InputEventKey.new()
	ev_rename.keycode = KEY_F2
	rename.events.append(ev_rename)

	# search
	var ev_search = InputEventKey.new()
	if OS.get_name() == "OSX":
		ev_search.keycode = KEY_F
		ev_search.command = true
	else:
		ev_search.keycode = KEY_F
		ev_search.ctrl_pressed = true
	search.events.append(ev_search)

	# confirm
	var ev_confirm = InputEventKey.new()
	ev_confirm.keycode = KEY_ENTER
	confirm.events.append(ev_confirm)
