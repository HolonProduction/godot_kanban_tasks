@tool
extends Button

var default_expand_icon = preload("expand.svg")
var default_collapse_icon = preload("collapse.svg")

@export var expanded: bool = true:
	set(value):
		if value != expanded:
			expanded = value
			__update_icon()
			state_changed.emit(expanded)
@export var use_theme: bool = false:
	set(value):
		if value != use_theme:
			use_theme = value
			__update_icon()

signal state_changed(expanded: bool)

func _init():
	focus_mode = Control.FOCUS_NONE
	flat = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pressed.connect(__on_pressed)
	__update_icon()
	
func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		__update_icon()
	
func __update_icon():
	if use_theme:
		if expanded:
			icon = get_theme_icon("collapse")
		else:
			icon = get_theme_icon("expand")
	else:
		if expanded:
			icon = default_collapse_icon
		else:
			icon = default_expand_icon

func __on_pressed():
	expanded = !expanded
