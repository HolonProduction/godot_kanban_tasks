tool
extends VBoxContainer

enum INTENTION {REPLACE, ADDITION}

var edit: LineEdit
var label: Label
var old_focus: Control = null

export var text: String = "" setget set_text, get_text

export(INTENTION) var default_intention := INTENTION.ADDITION
export var double_click := true

signal text_changed(new_text)
signal text_entered(new_text)

func set_text(value):
	text = value
	update_content()
	emit_signal("text_changed", text)

func get_text():
	return text

func update_content(val=null):
	if val is String:
		text = val
	if label:
		label.text = text
	if edit:
		edit.text = text

func _ready():
	self.alignment = BoxContainer.ALIGN_CENTER
	
	label = Label.new()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	
	#TODO forward to settings
	label.autowrap = true
	label.max_lines_visible = 2
	
	label.connect("gui_input", self, "label_input")
	add_child(label)
	
	edit = LineEdit.new()
	edit.visible = false
	edit.size_flags_horizontal = SIZE_EXPAND_FILL
	edit.size_flags_vertical = SIZE_FILL
	edit.connect("text_entered", self, "edit_text_entered")
	edit.connect("gui_input", self, "edit_input")
	add_child(edit)
	
	update_content()

func label_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index==BUTTON_LEFT and (event.is_doubleclick() if double_click else true):
		get_tree().set_input_as_handled()
		show_edit()

func edit_input(event):
	if event is InputEventKey and event.is_pressed() and event.is_action("ui_cancel"):
		show_label(false)

func edit_text_entered(_new):
	update_content(edit.text)
	show_label()
	emit_signal("text_entered")

func _input(event):
	if (event is InputEventMouseButton) and event.pressed and edit.visible:
		var local = edit.make_input_local(event)
		if not Rect2(Vector2(0,0), edit.rect_size).has_point(local.position):
			show_label()

func show_edit(p_intention=null):
	if edit.visible:
		return
	
	if focus_mode == FOCUS_NONE:
		old_focus = get_focus_owner()
	
	var intention = p_intention
	if intention == null:
		intention = default_intention
	update_content()
	label.visible = false
	edit.visible = true
	edit.grab_focus()
	match intention:
		INTENTION.ADDITION:
			edit.caret_position = len(edit.text)
		INTENTION.REPLACE:
			edit.select_all()

func show_label(apply_changes=true):
	if label.visible:
		return
	
	if apply_changes:
		update_content(edit.text)
		emit_signal("text_changed", text)
	
	if not is_instance_valid(old_focus):
		if focus_mode == FOCUS_NONE:
			edit.release_focus()
		else:
			grab_focus()
	else:
		old_focus.grab_focus()
	
	edit.visible = false
	label.visible = true
