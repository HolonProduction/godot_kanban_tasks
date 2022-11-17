#@standalone
# The line above is needed for standalone detection. Do not modify it.
@tool
extends EditorPlugin

## The StandalonePlugin implementation for in editor use.
##
## This file violates DRY. It should not contain references to other files
## of standalone plugin. This allows the future use as editor plugin.


## Additional containers for add_control_to_container
enum {
#	CONTAINER_TOOLBAR = 0,
#	CONTAINER_SPATIAL_EDITOR_MENU = 1,
#	CONTAINER_SPATIAL_EDITOR_SIDE_LEFT = 2,
#	CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT = 3,
#	CONTAINER_SPATIAL_EDITOR_BOTTOM = 4,
#	CONTAINER_CANVAS_EDITOR_MENU = 5,
#	CONTAINER_CANVAS_EDITOR_SIDE_LEFT = 6,
#	CONTAINER_CANVAS_EDITOR_SIDE_RIGHT = 7,
#	CONTAINER_CANVAS_EDITOR_BOTTOM = 8,
#	CONTAINER_INSPECTOR_BOTTOM = 9,
#	CONTAINER_PROJECT_SETTING_TAB_LEFT = 10,
#	CONTAINER_PROJECT_SETTING_TAB_RIGHT = 11,

	CONTAINER_LAUNCH_PAD = 12,
}


func save_project_settings() -> int:
	return ProjectSettings.save()


func add_control_to_container(container: int, control: Control) -> void:
	# Filter for valid editor containers
	if (container in [
		CONTAINER_TOOLBAR, CONTAINER_SPATIAL_EDITOR_MENU,
		CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT,
		CONTAINER_CANVAS_EDITOR_BOTTOM, CONTAINER_CANVAS_EDITOR_MENU,
		CONTAINER_CANVAS_EDITOR_SIDE_LEFT, CONTAINER_CANVAS_EDITOR_SIDE_RIGHT,
		CONTAINER_CANVAS_EDITOR_BOTTOM, CONTAINER_INSPECTOR_BOTTOM,
		CONTAINER_PROJECT_SETTING_TAB_LEFT, CONTAINER_PROJECT_SETTING_TAB_RIGHT,
	]):
		super.add_control_to_container(container, control)


func remove_control_from_container(container: int, control: Control) -> void:
	# Filter for valid editor containers
	if (container in [
		CONTAINER_TOOLBAR, CONTAINER_SPATIAL_EDITOR_MENU,
		CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT,
		CONTAINER_CANVAS_EDITOR_BOTTOM, CONTAINER_CANVAS_EDITOR_MENU,
		CONTAINER_CANVAS_EDITOR_SIDE_LEFT, CONTAINER_CANVAS_EDITOR_SIDE_RIGHT,
		CONTAINER_CANVAS_EDITOR_BOTTOM, CONTAINER_INSPECTOR_BOTTOM,
		CONTAINER_PROJECT_SETTING_TAB_LEFT, CONTAINER_PROJECT_SETTING_TAB_RIGHT,
	]):
		super.remove_control_from_container(container, control)


func add_menu(menu: PopupMenu) -> void:
	pass


func remove_menu(menu: PopupMenu) -> void:
	pass
