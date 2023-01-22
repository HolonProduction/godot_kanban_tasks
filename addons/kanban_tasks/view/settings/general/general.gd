@tool
extends VBoxContainer


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __EditContext := preload("res://addons/kanban_tasks/view/edit_context.gd")
const __SettingData := preload("res://addons/kanban_tasks/data/settings.gd")

var data: __SettingData = null

@onready var show_description_preview: CheckBox = %ShowDescriptionPreview


func _ready() -> void:
	await get_tree().create_timer(0.0).timeout
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	data = ctx.settings
	data.changed.connect(update)
	update()

	show_description_preview.toggled.connect(func(x): __apply_changes())


func update() -> void:
	show_description_preview.button_pressed = data.show_description_preview


func __apply_changes() -> void:
	if data.changed.is_connected(update):
		data.changed.disconnect(update)

	data.show_description_preview = show_description_preview.button_pressed

	data.changed.connect(update)
