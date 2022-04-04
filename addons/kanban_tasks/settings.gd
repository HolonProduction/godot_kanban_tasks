tool
extends AcceptDialog


const EditLabel = preload('./edit_label/edit_label.gd')

onready var category_container: PanelContainer = $VBoxContainer/Categories
onready var category_holder: VBoxContainer = $VBoxContainer/Categories/VBoxContainer/VBoxContainer
onready var category_add: Button = $VBoxContainer/Categories/VBoxContainer/Header/Add
onready var board = $'../../../VBoxContainer'


class CategoryEntry extends HBoxContainer:
	var title
	var delete: Button
	var managed_category
	var board
	
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
		
		delete = Button.new()
		delete.connect("pressed", self, "__on_delete")
		delete.focus_mode = FOCUS_NONE
		add_child(delete)
		
		board.connect("categories_changed", self, "__on_categories_changed")
		
		__on_categories_changed()
	
	func _exit_tree():
		board.disconnect("categories_changed", self, "__on_categories_changed")
	
	func _notification(what):
		match(what):
			NOTIFICATION_THEME_CHANGED:
				if is_instance_valid(delete):
					delete.icon = get_icon('Remove', 'EditorIcons')
	
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
	var cat = board.construct_category("New Category", Color.coral)
	category_holder.add_child(CategoryEntry.new(board, cat))
