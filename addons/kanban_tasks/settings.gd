tool
extends AcceptDialog


const EditLabel = preload('./edit_label/edit_label.gd')

onready var category_container: PanelContainer = $ScrollContainer/VBoxContainer/Categories
onready var category_holder: VBoxContainer = $ScrollContainer/VBoxContainer/Categories/VBoxContainer/VBoxContainer
onready var category_add: Button = $ScrollContainer/VBoxContainer/Categories/VBoxContainer/Header/Add
onready var board = $'../../../VBoxContainer'


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
	
	yield(board, 'ready')
	for category in board.categories:
		category_holder.add_child(CategoryEntry.new(board, category))

func _notification(what):
	match(what):
		NOTIFICATION_THEME_CHANGED:
			if is_instance_valid(category_container):
				category_container.add_stylebox_override('panel', get_stylebox('bg', 'Tree'))
			if is_instance_valid(category_add):
				category_add.icon = get_icon('Add', 'EditorIcons')

func __on_add_category():
	var randomizer = RandomNumberGenerator.new()
	randomizer.randomize()
	var color = Color.from_hsv(randomizer.randf(), randomizer.randf_range(0.8, 1.0), randomizer.randf_range(0.7, 1.0))
	
	var cat = board.construct_category("New Category", color)
	
	var ent = CategoryEntry.new(board, cat)
	category_holder.add_child(ent)
	
	ent.grab_focus()
	ent.show_edit(preload("./edit_label/edit_label.gd").INTENTION.REPLACE)
