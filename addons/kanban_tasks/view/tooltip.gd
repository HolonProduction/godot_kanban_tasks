@tool
class_name Tooltip extends RichTextLabel

@export var mimicked_paragraph_spacing_font_size: int = 6

func _init():
	resized.connect(__on_resized)

func mimic_paragraphs():
	var what_in_order: PackedStringArray = [
		"[/p]\n[p]",
		"[p][/p]",
		"[p]",
		"[/p]",
	]
	var forwhat = "\n[font_size=%s]\n[/font_size]\n" % mimicked_paragraph_spacing_font_size
	var text := self.text
	for what in what_in_order:
		text = text.replace(what, forwhat)
	self.text = text


func __on_resized():
	# Reduce width if unnecessary, as there is no line wraps
	var stylebox = get_theme_stylebox("normal")
	var required_width = get_content_width() + stylebox.content_margin_left + stylebox.content_margin_right
	if required_width < custom_minimum_size.x: 
		custom_minimum_size.x = required_width

