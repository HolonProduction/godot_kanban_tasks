extends Node


## Global stuff for the view system.


## The undo redo for task operations.
var undo_redo := UndoRedo.new()

## uuid of the object that should have focus. This is used to persist focus
## when updating some views.
var focus: String = ""
