@tool
extends VBoxContainer


const __Singletons := preload("res://addons/kanban_tasks/plugin_singleton/singletons.gd")
const __EditContext := preload("res://addons/kanban_tasks/view/edit_context.gd")
const __SettingData := preload("res://addons/kanban_tasks/data/settings.gd")

var data: __SettingData = null

var file_dialog_save_option: CheckBox

@onready var show_description_preview: CheckBox = %ShowDescriptionPreview
@onready var show_steps_preview: CheckBox = %ShowStepsPreview
@onready var show_category_on_board: CheckBox = %ShowCategoriesOnBoard
@onready var edit_step_details_exclusively: CheckBox = %EditStepDetailsExclusively
@onready var max_displayed_lines_in_description: SpinBox = %MaxDisplayedLinesInDescription
@onready var description_on_board: OptionButton = %DescriptionOnBoard
# Keep IDs of the items of StepsOnBoard in sync with the values of setting.gd/StepsOnBoard
@onready var steps_on_board: OptionButton = %StepsOnBoard
@onready var max_steps_on_board: SpinBox = %MaxStepsOnBoard
@onready var data_file_path_label: Control = %DataFilePathLabel
@onready var data_file_path_container: Control = %DataFilePathContainer
@onready var data_file_path: LineEdit = %DataFilePath
@onready var data_file_path_button: Button = %DataFilePathButton
@onready var file_dialog: FileDialog = %FileDialog


func _ready() -> void:
	await get_tree().create_timer(0.0).timeout
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	data = ctx.settings
	data.changed.connect(update)
	update()

	show_description_preview.toggled.connect(func(x): __apply_changes())
	show_steps_preview.toggled.connect(func(x): __apply_changes())
	show_category_on_board.toggled.connect(func(x): __apply_changes())
	edit_step_details_exclusively.toggled.connect(func(x): __apply_changes())
	max_displayed_lines_in_description.value_changed.connect(func(x): __apply_changes())
	description_on_board.item_selected.connect(func(x): __apply_changes())
	steps_on_board.item_selected.connect(func(x): __apply_changes())
	max_steps_on_board.value_changed.connect(func(x): __apply_changes())
	if not Engine.is_editor_hint():
		data_file_path_label.visible = false
		data_file_path_container.visible = false
	data_file_path_button.pressed.connect(__open_data_file_path_dialog)
	file_dialog_save_option = CheckBox.new()
	file_dialog_save_option.text = "Save current data to the new file location"
	file_dialog_save_option.toggled.connect(__file_dialog_save_option_toggled)
	file_dialog.get_vbox().add_child(file_dialog_save_option)


func __open_data_file_path_dialog():
	file_dialog_save_option.visible = true
	file_dialog_save_option.button_pressed = false
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.clear_filters()
	file_dialog.add_filter("*.kanban, *.json", "Kanban Board")
	file_dialog.file_selected.connect(__update_editor_data_file, CONNECT_ONE_SHOT)
	file_dialog.canceled.connect(func (): file_dialog.file_selected.disconnect(__update_editor_data_file))
	file_dialog.popup_centered(file_dialog.size)


func __file_dialog_save_option_toggled(button_pressed: bool):
	if button_pressed:
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	else:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE


func __update_editor_data_file(path: String):
	data_file_path.text = path
	__apply_changes()
	var ctx: __EditContext = __Singletons.instance_of(__EditContext, self)
	if file_dialog_save_option.button_pressed:
		ctx.save_board.emit()
	else:
		ctx.reload_board.emit()


func update() -> void:
	show_description_preview.button_pressed = data.show_description_preview
	show_steps_preview.button_pressed = data.show_steps_preview
	show_category_on_board.button_pressed = data.show_category_on_board
	edit_step_details_exclusively.button_pressed = data.edit_step_details_exclusively
	max_displayed_lines_in_description.value = data.max_displayed_lines_in_description
	max_steps_on_board.value = data.max_steps_on_board

	description_on_board.select(description_on_board.get_item_index(data.description_on_board))
	steps_on_board.select(steps_on_board.get_item_index(data.steps_on_board))

	data_file_path.text = data.editor_data_file_path


func __apply_changes() -> void:
	if data.changed.is_connected(update):
		data.changed.disconnect(update)

	# TODO: Make ability to turn off data.changed signaling. Below code will tirgger it 4 times, while its enough for once
	# OR
	# TODO: Instead calling compund update function, call changed.emit separatelly for setting data property change. 1 trigger per one change, and not 4 tigger per 1 change.
	data.show_description_preview = show_description_preview.button_pressed
	data.show_steps_preview = show_steps_preview.button_pressed
	data.show_category_on_board = show_category_on_board.button_pressed
	data.edit_step_details_exclusively = edit_step_details_exclusively.button_pressed
	data.max_displayed_lines_in_description = max_displayed_lines_in_description.value
	data.description_on_board = description_on_board.get_selected_id()
	data.steps_on_board = steps_on_board.get_selected_id()
	data.max_steps_on_board = max_steps_on_board.value
	data.editor_data_file_path = data_file_path.text

	data.changed.connect(update)
