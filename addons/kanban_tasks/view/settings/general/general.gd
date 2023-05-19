@tool
extends VBoxContainer


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __EditContext := preload("res://addons/kanban_tasks/view/edit_context.gd")
const __SettingData := preload("res://addons/kanban_tasks/data/settings.gd")

var data: __SettingData = null

@onready var show_description_preview: CheckBox = %ShowDescriptionPreview
@onready var edit_step_details_exclusively: CheckBox = %EditStepDetailsExclusively
@onready var max_displayed_lines_in_description: SpinBox = %MaxDisplayedLinesInDescription


func _ready() -> void:
	await get_tree().create_timer(0.0).timeout
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	data = ctx.settings
	data.changed.connect(update)
	update()

	show_description_preview.toggled.connect(func(x): __apply_changes())
	edit_step_details_exclusively.toggled.connect(func(x): __apply_changes())
	max_displayed_lines_in_description.value_changed.connect(func(x): __apply_changes())


func update() -> void:
	show_description_preview.button_pressed = data.show_description_preview
	edit_step_details_exclusively.button_pressed = data.edit_step_details_exclusively
	max_displayed_lines_in_description.value = data.max_displayed_lines_in_description


func __apply_changes() -> void:
	if data.changed.is_connected(update):
		data.changed.disconnect(update)

	data.show_description_preview = show_description_preview.button_pressed
	data.edit_step_details_exclusively = edit_step_details_exclusively.button_pressed
	data.max_displayed_lines_in_description = max_displayed_lines_in_description.value

	data.changed.connect(update)
