extends RefCounted

## Replicates the API of EditorUndoRedoManager.
##
## Only uses one UndoRedo object.


enum {
	GLOBAL_HISTORY = 0,
	INVALID_HISTORY = -99,
}

var __undo_redo: UndoRedo = UndoRedo.new()
# Default value for all varargs. Indicates, that no value was passed.
var __undefined: Object = Object.new()

var __is_committing: bool = false


func add_do_method(object: Object, method: StringName, p1 = __undefined,
		p2 = __undefined, p3 = __undefined, p4 = __undefined, p5 = __undefined,
		p6 = __undefined, p7 = __undefined, p8 = __undefined) -> void:
	var callable = Callable(object, method)
	callable = __bind_varargs(callable, [p1, p2, p3, p4, p5, p6, p7, p8])

	__undo_redo.add_do_method(callable)


func add_undo_method(object: Object, method: StringName, p1 = __undefined,
		p2 = __undefined, p3 = __undefined, p4 = __undefined, p5 = __undefined,
		p6 = __undefined, p7 = __undefined, p8 = __undefined) -> void:
	var callable = Callable(object, method)
	callable = __bind_varargs(callable, [p1, p2, p3, p4, p5, p6, p7, p8])

	__undo_redo.add_undo_method(callable)


func add_do_property(object: Object, property: StringName, value) -> void:
	__undo_redo.add_do_property(object, property, value)


func add_undo_property(object: Object, property: StringName, value) -> void:
	__undo_redo.add_undo_property(object, property, value)


func add_do_reference(object: Object) -> void:
	__undo_redo.add_do_reference(object)


func add_undo_reference(object: Object) -> void:
	__undo_redo.add_undo_reference(object)


func commit_action(execute: bool = true) -> void:
	# TODO Find out whether the bool is needed as GDScript is not async.
	__is_committing = true
	__undo_redo.commit_action(execute)
	__is_committing = false


func create_action(name: String, merge_mode: int = 0,
		_custom_context: Object = null) -> void:
	__undo_redo.create_action(name, merge_mode)


func get_history_undo_redo(_id: int) -> UndoRedo:
	return __undo_redo


func get_object_history_id(_object: Object) -> int:
	return GLOBAL_HISTORY


func is_commiting_action() -> bool:
	return __is_committing


# Binds a vararg array to a callable.
# Operates in place. The returned array is the same reference as the passed.
func __bind_varargs(callable: Callable, args: Array) -> Callable:
	for i in range(len(args) - 1, -1, -1):
		if args[i] != __undefined:
			callable = callable.bind(args[i])
	return callable

