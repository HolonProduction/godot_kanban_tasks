@tool
extends AcceptDialog


const __BoardData := preload("res://addons/kanban_tasks/data/board.gd")
const __CategoriesScene := preload("res://addons/kanban_tasks/view/settings/categories/categories.tscn")
const __CategoriesScript := preload("res://addons/kanban_tasks/view/settings/categories/categories.gd")

@onready var category_settings: __CategoriesScript = %Categories
@onready var stage_settings = %Stages


var board_data: __BoardData


func _ready() -> void:
	# Wait for board to set board_data.
	await get_tree().create_timer(0.0).timeout

	category_settings.board_data = board_data
	stage_settings.board_data = board_data
	about_to_popup.connect(stage_settings.update)
	about_to_popup.connect(category_settings.update)


# Workaround for godotengine/godot#70451
func popup_centered_ratio_no_fullscreen(ratio: float = 0.8) -> void:
	var viewport: Viewport = get_parent().get_viewport()
	popup(Rect2i(Vector2(viewport.position) + viewport.size / 2.0 - viewport.size * ratio / 2.0, viewport.size * ratio))
