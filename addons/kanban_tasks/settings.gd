tool
extends AcceptDialog


const EditLabel = preload('./edit_label/edit_label.gd')

onready var category_container: PanelContainer = $TabContainer/Categories/Categories
onready var stages_container: PanelContainer = $TabContainer/Stages/PanelContainer
onready var general_container: PanelContainer = $TabContainer/General/PanelContainer
onready var category_holder: VBoxContainer = $TabContainer/Categories/Categories/ScrollContainer/VBoxContainer
onready var category_add: Button = $TabContainer/Categories/Header/Add
onready var board = $'../../../VBoxContainer'

onready var show_details_check_box: CheckBox = $TabContainer/General/PanelContainer/ScrollContainer/VBoxContainer/ShowDetails

onready var column_holder: HBoxContainer = $TabContainer/Stages/PanelContainer/ScrollContainer/CenterContainer/ColumnHolder
onready var column_add: Button = $TabContainer/Stages/PanelContainer/ScrollContainer/CenterContainer/ColumnHolder/AddColumn/Add

onready var warning_sign: Button = $TabContainer/Stages/PanelContainer/Warning/WarningSign


class StageEntry extends Control:
	var board
	var managed_stage
	
	var button: Button
	var cent
	
	func _init(p_board, p_stage):
		board = p_board
		managed_stage = p_stage
	
	func _ready():
		button = Button.new()
		button.set_anchors_preset(Control.PRESET_WIDE)
		button.hint_tooltip = managed_stage.title
		add_child(button)
		
		button.focus_mode = Control.FOCUS_NONE
		set_v_size_flags(SIZE_EXPAND_FILL)
		rect_min_size = Vector2(70, 50)
		
		cent = CenterContainer.new()
		cent.set_anchors_preset(Control.PRESET_WIDE)
		cent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(cent)
		
		var plus := TextureRect.new()
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cent.add_child(plus)
		button.connect("pressed", self, "__on_delete")
		
		board.connect("columns_changed", self, "__on_stages_changed")
		board.connect("stages_changed", self, "__on_stages_changed")
		
		__on_stages_changed()
	
	func __on_stages_changed():
		button.disabled = len(board.columns) == 1 and len(board.stages) == 1
	
	func __on_delete():
		get_parent().remove_stage(self)
	
	func _notification(what):
		match(what):
			NOTIFICATION_THEME_CHANGED:
				if is_instance_valid(cent):
					cent.get_child(0).texture = get_icon('Remove', 'EditorIcons')
					button.add_stylebox_override('normal', get_stylebox('panel', 'TabContainer'))
					button.add_stylebox_override('hover', get_stylebox('read_only', 'LineEdit'))
					button.add_stylebox_override('pressed', get_stylebox('read_only', 'LineEdit'))


class ColumnEntry extends VBoxContainer:
	var board
	var managed_column
	
	var add: Button
	
	var confirm_not_empty: ConfirmationDialog
	var confirm_not_empty_select: OptionButton
	var confirm_empty: ConfirmationDialog
	var confirm_empty_check: CheckBox
	
	func _init(p_board, p_column):
		board = p_board
		managed_column = p_column
	
	func _ready():
		confirm_not_empty = $"../../../../../../../../ConfirmNotEmpty"
		confirm_not_empty_select = $"../../../../../../../../ConfirmNotEmpty/VBoxContainer/OptionButton"
		confirm_empty = $"../../../../../../../../ConfirmEmpty"
		confirm_empty_check = $"../../../../../../../TabContainer/Stages/Header/CheckBox"
		
		add = Button.new()
		add.rect_min_size = Vector2(70, 40)
		add_child(add)
		
		var cent = CenterContainer.new()
		cent.set_anchors_preset(Control.PRESET_WIDE)
		cent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add.add_child(cent)
		add.focus_mode = Control.FOCUS_NONE
		
		add.connect("pressed", self, "__on_add_stage")
		
		var plus := TextureRect.new()
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cent.add_child(plus)
		
		if len(managed_column.stages) == 0:
			__on_add_stage(null)
		else:
			for stage in managed_column.stages:
				__on_add_stage(stage)
	
	func remove_stage(stage):
		if len(stage.managed_stage.tasks) == 0:
			if confirm_empty_check.pressed:
				if confirm_empty.is_connected("confirmed", self, "__on_remove_stage_confirmed"):
					confirm_empty.disconnect("confirmed", self, "__on_remove_stage_confirmed")
				confirm_empty.connect("confirmed", self, "__on_remove_stage_confirmed", [stage], CONNECT_ONESHOT)
				confirm_empty.popup_centered()
			else:
				__on_remove_stage_confirmed(stage)
		else:
			confirm_not_empty_select.clear()
			for i in board.stages:
				if i != stage.managed_stage:
					confirm_not_empty_select.add_item(i.title, board.stage_index(i))
			
			if confirm_not_empty.is_connected("confirmed", self, "__on_move_tasks_confirmed"):
				confirm_not_empty.disconnect("confirmed", self, "__on_move_tasks_confirmed")
			confirm_not_empty.connect("confirmed", self, "__on_move_tasks_confirmed", [stage], CONNECT_ONESHOT)
			
			confirm_not_empty.popup_centered()
	
	func __on_move_tasks_confirmed(stage):
		var target = board.stages[confirm_not_empty_select.get_item_id(confirm_not_empty_select.selected)]
		for i in stage.managed_stage.tasks.duplicate():
			target.add_task(i)
		__on_remove_stage_confirmed(stage)
	
	func __on_remove_stage_confirmed(stage):
		board.delete_stage(stage.managed_stage)
		if get_child_count() <= 2:
			queue_free()
			board.delete_column(managed_column)
		else:
			stage.queue_free()
	
	func __on_add_stage(st = null):
		if st == null:
			st = board.construct_stage("New Stage")
			managed_column.add_stage(st)
		
		var stage = StageEntry.new(board, st)
		add_child(stage)
		move_child(add, get_child_count()-1)
	
	func _notification(what):
		match(what):
			NOTIFICATION_THEME_CHANGED:
				if is_instance_valid(add):
					add.get_child(0).get_child(0).texture = get_icon('Add', 'EditorIcons')
					add.add_stylebox_override('normal', get_stylebox('panel', 'TabContainer'))
					add.add_stylebox_override('hover', get_stylebox('read_only', 'LineEdit'))
					add.add_stylebox_override('pressed', get_stylebox('read_only', 'LineEdit'))


class CategoryEntry extends HBoxContainer:
	var title
	var delete: Button
	var color_picker: ColorPickerButton
	var managed_category
	var board
	var focus_box: StyleBoxFlat
	
	func _init(p_board, p_category):
		board = p_board
		managed_category = p_category
	
	func _ready():
		set_h_size_flags(SIZE_EXPAND_FILL)
		focus_mode = FOCUS_ALL
		
		title = EditLabel.new()
		title.set_h_size_flags(SIZE_EXPAND_FILL)
		title.text = managed_category.title
		title.connect("text_changed", managed_category, "set_title")
		add_child(title)
		
		color_picker = ColorPickerButton.new()
		color_picker.rect_min_size.x = 100
		color_picker.edit_alpha = false
		color_picker.color = managed_category.color
		color_picker.connect("color_changed", managed_category, "set_color")
		color_picker.focus_mode = Control.FOCUS_NONE
		color_picker.flat = true
		add_child(color_picker)
		
		delete = Button.new()
		delete.connect("pressed", self, "__on_delete")
		delete.focus_mode = FOCUS_NONE
		delete.flat = true
		add_child(delete)
		
		focus_box = StyleBoxFlat.new()
		focus_box.bg_color = Color(1, 1, 1, 0.1)
		
		board.connect("categories_changed", self, "__on_categories_changed")
		
		__on_categories_changed()
	
	func _exit_tree():
		board.disconnect("categories_changed", self, "__on_categories_changed")
	
	func _unhandled_key_input(event):
		if not board.can_handle_shortcut(self):
			return
			
		if not event.is_echo() and event.is_pressed():
			if board.shortcut_rename.is_shortcut(event):
				title.show_edit()
	
	func _notification(what):
		match(what):
			NOTIFICATION_THEME_CHANGED:
				if is_instance_valid(delete):
					delete.icon = get_icon('Remove', 'EditorIcons')
			NOTIFICATION_DRAW:
				if has_focus():
					focus_box.draw(get_canvas_item(), Rect2(Vector2.ZERO, get_rect().size))
	
	func show_edit(intention=null):
		title.show_edit(intention)
	
	func __on_categories_changed():
		delete.disabled = board.category_index(managed_category, true) == 0
	
	func __on_delete():
		if board.category_index(managed_category) != 0:
			for b in board.tasks:
				if b.category == managed_category:
					b.category = board.categories[0]
			board.delete_category(managed_category)
			queue_free()
		

func _ready():
	category_add.connect("pressed", self, "__on_add_category")
	column_add.connect("pressed", self, "__on_add_column")
	board.connect("stages_changed", self, "__on_stages_changed")
	board.connect("columns_changed", self, "__on_stages_changed")
	board.connect("settings_changed", self, "__on_settings_changed")
	
	show_details_check_box.pressed = board.show_details_preview
	show_details_check_box.connect('pressed', self, '__on_change_show_details')
	
	column_add.focus_mode = Control.FOCUS_NONE
	
	var cent = CenterContainer.new()
	cent.set_anchors_preset(Control.PRESET_WIDE)
	cent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_add.add_child(cent)
		
	var plus := TextureRect.new()
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cent.add_child(plus)
	
	yield(board, 'ready')
	for category in board.categories:
		category_holder.add_child(CategoryEntry.new(board, category))
	
	for column in board.columns:
		__on_add_column(column)

func __on_settings_changed():
	show_details_check_box.pressed = board.show_details_preview

func _notification(what):
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(category_container):
				category_container.add_stylebox_override('panel', get_stylebox('bg', 'Tree'))
			if is_instance_valid(category_add):
				category_add.icon = get_icon('Add', 'EditorIcons')
			if is_instance_valid(stages_container):
				stages_container.add_stylebox_override('panel', get_stylebox('bg', 'Tree'))
			if is_instance_valid(general_container):
				general_container.add_stylebox_override('panel', get_stylebox('bg', 'Tree'))
			if is_instance_valid(column_add):
				column_add.get_child(0).get_child(0).texture = get_icon('Add', 'EditorIcons')
				column_add.add_stylebox_override('normal', get_stylebox('panel', 'TabContainer'))
				column_add.add_stylebox_override('hover', get_stylebox('read_only', 'LineEdit'))
				column_add.add_stylebox_override('pressed', get_stylebox('read_only', 'LineEdit'))
			if is_instance_valid(warning_sign):
				warning_sign.icon = get_icon('NodeWarning', 'EditorIcons')


func __on_change_show_details():
	board.show_details_preview = show_details_check_box.pressed


func __on_add_column(column = null):
	if column == null:
		column = board.construct_column()
		board.column_holder.add_child(column)
	
	var ent = ColumnEntry.new(board, column)
	column.connect("change", self, "__on_stages_changed")
	column.connect("tree_exiting", self, "__on_column_remove", [column])
	column_holder.add_child(ent)
	column_holder.move_child(ent, column_holder.get_child_count()-2)

func __on_column_remove(column):
	column.disconnect("change", self, "__on_stages_changed")

func __on_add_category():
	var randomizer = RandomNumberGenerator.new()
	randomizer.randomize()
	var color = Color.from_hsv(randomizer.randf(), randomizer.randf_range(0.8, 1.0), randomizer.randf_range(0.7, 1.0))
	
	var cat = board.construct_category("New Category", color)
	
	var ent = CategoryEntry.new(board, cat)
	category_holder.add_child(ent)
	
	yield(get_tree().create_timer(0.0), "timeout")
	ent.grab_focus()
	ent.show_edit(preload("./edit_label/edit_label.gd").INTENTION.REPLACE)

func __on_stages_changed():
	var to_high = false
	
	for column in board.columns:
		if len(column.stages) > 3:
			to_high = true
	
	warning_sign.visible = to_high or len(board.columns) > 4
