@tool
class_name StepHolder extends VBoxContainer

const __StepData := preload("res://addons/kanban_tasks/data/step.gd")
const __StepEntry := preload("res://addons/kanban_tasks/view/details/step_entry.gd")

@export var scrollable: bool = true:
	set(value):
		if value != scrollable:
			scrollable = value
			__update_children_settings()
	
@export var steps_can_be_removed: bool = true:
	set(value):
		if value != steps_can_be_removed:
			steps_can_be_removed = value
			__update_children_settings()
@export var steps_can_be_reordered: bool = true:
	set(value):
		if value != steps_can_be_reordered:
			steps_can_be_reordered = value
			__update_children_settings
@export var steps_have_context_menu: bool = true:
	set(value):
		if value != steps_have_context_menu:
			steps_have_context_menu = value
			__update_children_settings

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var step_list: VBoxContainer = %StepList
@onready var remove_separator: HSeparator = %RemoveSeparator
@onready var remove_area: Button = %RemoveArea

signal entry_action_triggered(entry, action, meta)
signal entry_move_requesed(moved_entry, target_entry, move_after_target)

var __mouse_entered_step_list := false
var __move_target_entry: __StepEntry = null
var __move_after_target := false

func _init():
	pass

func _ready():
	remove_area.icon = get_theme_icon(&"Remove", &"EditorIcons")
	step_list.draw.connect(__on_step_list_draw)
	step_list.mouse_exited.connect(__on_step_list_mouse_exited)
	step_list.mouse_entered.connect(__on_step_list_mouse_entered)
	__update_children_settings()
	
func __update_children_settings():
	if scroll_container != null:
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if scrollable else ScrollContainer.SCROLL_MODE_DISABLED
	if remove_separator != null:
		remove_separator.visible = steps_can_be_removed
	if remove_area != null:
		remove_area.visible = steps_can_be_removed
	for entry in get_step_entries():
		entry.context_menu_enabled = steps_have_context_menu
	
func _get_drag_data(at_position: Vector2) -> Variant:
	if not steps_can_be_removed and not steps_can_be_reordered:
		return null
	for entry in get_step_entries():
		if entry.get_global_rect().has_point(get_global_transform() * at_position):
			var preview := Label.new()
			preview.text = entry.step_data.details
			set_drag_preview(preview)
			return entry
	return null

func __update_move_target(at_position: Vector2):
	var at_global_position := get_global_transform() * at_position
	# This __mouse_entered_step_list is needed here, as this seemed to be the only reliable solution, as:
	# 1) something is NOK with transforming at_position to global and compare with step_list.global_rect 
	# 2) cannot decide what is the visible rect of the step_list
	# 3) _can_drop_data was called even after mouse is outside the list (to the bottom direction)
	if __mouse_entered_step_list:
		var closes_entry: __StepEntry = null
		var smallest_distance: float
		var position_is_after_closes_entry: bool
		for e in get_step_entries():
			var entry_global_rect = e.get_global_rect()
			var distance := abs(at_global_position.y - entry_global_rect.position.y)
			if closes_entry == null or distance < smallest_distance:
				closes_entry = e
				smallest_distance = distance
				position_is_after_closes_entry = false
			distance = abs(at_global_position.y - entry_global_rect.end.y)
			if closes_entry == null or distance < smallest_distance:
				closes_entry = e
				smallest_distance = distance
				position_is_after_closes_entry = true
		__move_target_entry = closes_entry
		__move_after_target = position_is_after_closes_entry
	else:
		__move_target_entry = null
	step_list.queue_redraw()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not steps_can_be_removed and not steps_can_be_reordered:
		return false
	if data is Node and __is_step_entry(data):
		if remove_area.get_global_rect().has_point(get_global_transform() * at_position):
			return true
		__update_move_target(at_position)
		return (__move_target_entry != null)
	return false
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if __move_target_entry != null:
		entry_move_requesed.emit(data, __move_target_entry, __move_after_target)
	if data is Node and __is_step_entry(data):
		if remove_area.get_global_rect().has_point(get_global_transform() * at_position):
			data.__action(__StepEntry.Actions.DELETE)

func __on_step_list_mouse_entered():
	__mouse_entered_step_list = true
	
func __on_step_list_mouse_exited():
	__mouse_entered_step_list = false
	__update_move_target(get_local_mouse_position())
	
func __on_step_list_draw():
	if __move_target_entry != null:
		var target_rect := step_list.get_global_transform().inverse() * __move_target_entry.get_global_rect()
		var separation = step_list.get_theme_constant("separation")
		var preview_rect := Rect2(Vector2(0, target_rect.end.y if __move_after_target else target_rect.position.y - separation), \
				Vector2(target_rect.size.x, separation))
		if preview_rect.position.y < 0:
			preview_rect.position.y = 0
		if preview_rect.end.y > step_list.size.y:
			preview_rect.position.y -= (preview_rect.end.y - step_list.size.y)
		step_list.draw_rect(preview_rect, get_theme_color("step_move_review_color"))
	
	
func __is_step_entry(node: Node) -> bool:
	return node.get_meta(__StepEntry.__meta_name, false) != false

func clear_steps():
	for step in get_step_entries():
		step_list.remove_child(step)
		step.queue_free()
	
func add_step(step: __StepData):
	var entry := __StepEntry.new()
	entry.step_data = step
	entry.show_behind_parent = true
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_list.add_child(entry)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.action_triggered.connect(__on_entry_action_triggered)
	entry.context_menu_enabled = steps_have_context_menu
	
func __on_entry_action_triggered(entry, action, meta):
	entry_action_triggered.emit(entry, action, meta)

func get_step_entries() -> Array[__StepEntry]:
	var step_entries: Array[__StepEntry] = []
	if step_list != null:
		for child in step_list.get_children():
			if __is_step_entry(child):
				step_entries.append(child)
	return step_entries
	