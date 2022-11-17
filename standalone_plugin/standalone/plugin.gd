extends Node

## The standalone plugin implementation.


signal main_screen_changed(screen_name: String)
signal project_settings_changed()
signal resource_saved(resource: Resource)
signal scene_changed(scene_root: Node)
signal scene_closed(filepath: String)


## Container constants and new containers.
enum {
	CONTAINER_TOOLBAR = 0,
	CONTAINER_SPATIAL_EDITOR_MENU = 1,
	CONTAINER_SPATIAL_EDITOR_SIDE_LEFT = 2,
	CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT = 3,
	CONTAINER_SPATIAL_EDITOR_BOTTOM = 4,
	CONTAINER_CANVAS_EDITOR_MENU = 5,
	CONTAINER_CANVAS_EDITOR_SIDE_LEFT = 6,
	CONTAINER_CANVAS_EDITOR_SIDE_RIGHT = 7,
	CONTAINER_CANVAS_EDITOR_BOTTOM = 8,
	CONTAINER_INSPECTOR_BOTTOM = 9,
	CONTAINER_PROJECT_SETTING_TAB_LEFT = 10,
	CONTAINER_PROJECT_SETTING_TAB_RIGHT = 11,

	CONTAINER_LAUNCH_PAD = 12,
}

enum {
	DOCK_SLOT_LEFT_UL = 0,
	DOCK_SLOT_LEFT_BL = 1,
	DOCK_SLOT_LEFT_UR = 2,
	DOCK_SLOT_LEFT_BR = 3,
	DOCK_SLOT_RIGHT_UL = 4,
	DOCK_SLOT_RIGHT_BL = 5,
	DOCK_SLOT_RIGHT_UR = 6,
	DOCK_SLOT_RIGHT_BR = 7,
	DOCK_SLOT_MAX = 8,
}


################################################################################
# Supported virtual methods
################################################################################
func _disable_plugin() -> void: pass


func _enable_plugin() -> void: pass


func _get_plugin_icon() -> Texture2D: return null


func _get_plugin_name() -> String: return ""


func _get_window_layout(_configuration: ConfigFile) -> void: pass


func _has_main_screen() -> bool: return false


func _make_visible(_visible: bool) -> void: pass


func _save_external_data() -> void: pass


func _set_window_layout(_configuration: ConfigFile) -> void: pass


################################################################################
# Supported methods
################################################################################
func add_control_to_bottom_panel(control: Control, title: String) -> Button:
	return __get_ui_root().add_bottom_panel_item(control, title)


func remove_control_from_bottom_panel(control: Control) -> void:
	__get_ui_root().remove_bottom_panel_item(control)


func hide_bottom_panel() -> void:
	__get_ui_root().hide_bottom_panel()


func make_bottom_panel_item_visible(item: Control) -> void:
	__get_ui_root().make_bottom_panel_item_visible(item)


func add_control_to_container(container: int, control: Control) -> void:
	match container:
		CONTAINER_TOOLBAR:
			__get_ui_root().title_bar.add_child(control)
		CONTAINER_LAUNCH_PAD:
			__get_ui_root().add_control_to_launch_pad(control)


func remove_control_from_container(container: int, control: Control) -> void:
	match container:
		CONTAINER_TOOLBAR:
			__get_ui_root().title_bar.remove_child(control)
		CONTAINER_LAUNCH_PAD:
			__get_ui_root().remove_control_from_launch_pad(control)


func add_control_to_dock(slot: int, control: Control) -> void:
	__get_ui_root().add_control_to_dock(slot, control)


func remove_control_from_docks(control: Control) -> void:
	__get_ui_root().remove_control_from_dock(control)


func get_editor_interface() -> Variant:
	return __get_ui_root().interface


func queue_save_layout() -> void:
	__get_ui_root().__save_docks.call_deferred()


func get_undo_redo() -> Variant:
	return __get_ui_root().undo_redo_manager


func save_project_settings() -> int:
	return ProjectSettings.save_custom(Env.override_settings_path)


func add_menu(menu: PopupMenu) -> void:
	__get_ui_root().main_menu.add_child(menu)


func remove_menu(menu: PopupMenu) -> void:
	__get_ui_root().main_menu.remove_child(menu)


################################################################################
# Dummy methods
################################################################################
func add_autoload_singleton(_name: String, _path: String) -> void: pass
func add_custom_type(_type: String, _base: String, _script: Script,
	_icon: Texture2D) -> void: pass
func add_debugger_plugin(_script: Script) -> void: pass
func add_export_plugin(_plugin) -> void: pass
func add_import_plugin(_importer, _first_priority: bool = false) -> void: pass
func add_inspector_plugin(_plugin) -> void: pass
func add_node_3d_gizmo_plugin(_plugin) -> void: pass
func add_scene_format_importer_plugin(_scene_format_importer,
	_first_priority: bool = false) -> void: pass
func add_scene_post_import_plugin(_scene_import_plugin,
	_first_priority: bool = false) -> void: pass
func add_tool_menu_item(_name: String, _callable: Callable) -> void: pass
func add_tool_submenu_item(_name: String, _submenut: PopupMenu) -> void: pass
func add_translation_parser_plugin(_parser) -> void: pass
func add_undo_redo_inspector_hook_callback(_callable: Callable) -> void: pass
func get_export_as_menu() -> PopupMenu: return null
func get_script_create_dialog(): return null
func remove_autoload_singleton(_name: String) -> void: pass
func remove_custom_type(_type: String) -> void: pass
func remove_debugger_plugin(_script: Script) -> void: pass
func remove_export_plugin(_plugin) -> void: pass
func remove_import_plugin(_plugin) -> void: pass
func remove_inspector_plugin(_plugin) -> void: pass
func remove_node_3d_gizmo_plugin(_plugin) -> void: pass
func remove_scene_format_importer_plugin(_scene_format_importer) -> void: pass
func remove_scene_post_import_plugin(_scene_import_plugin) -> void: pass
func remove_tool_menu_item(_name: String) -> void: pass
func remove_translation_parser_plugin(_parser) -> void: pass
func remove_undo_redo_inspector_hook_callback(_callable: Callable) -> void: pass
func set_force_draw_over_forwardin_enabled() -> void: pass
func set_input_event_forwarding_always_enabled() -> void: pass
func update_overlays() -> int: return 1


################################################################################
# Own methods
################################################################################
func __get_ui_root():
	return get_tree().current_scene
