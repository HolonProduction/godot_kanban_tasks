tool
extends Control


var board

# currently the array is filled with indexes in the init call
# but upon _ready objects get stored inside (when they where loaded)
# this behaviour results in the unusability of it before the _ready call
# this could be changed when/if godot supports parameters for 
# .instance() like it works with .new()
var stages: Array

signal change()

func init(board, stages):
	self.board = board
	
	self.stages = stages

func _ready():
	for s in stages.duplicate():
		add_stage(board.stages[s], true)
		stages.erase(s)

func add_stage(stage: Node, silent = false):
	if stage.is_inside_tree():
		stage.get_owner().remove_stage(stage, silent)
	add_child(stage)
	stage.set_owner(self)
	stages.append(stage)
	if is_inside_tree() and not silent:
		emit_signal("change")

func serialize():
	var s = []
	for i in stages:
		s.append(board.stage_index(i))
	var res = {
		"stages": s
	}
	return res

func remove_stage(stage: Node, silent = false):
	remove_child(stage)
	stages.erase(stage)
	if is_inside_tree() and not silent:
		emit_signal("change")
