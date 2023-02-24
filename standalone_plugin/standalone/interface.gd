extends RefCounted

## Implementation of runtime EditorInterface
##
## The API is compatible, but most things won't do anything.


class StandalonePaths extends Object:
	func get_cache_dir() -> String:
		return "user://cache/"


	func get_config_dir() -> String:
		return "user://config/"


	func get_data_dir() -> String:
		return "user://data/"


	func get_project_settings_dir() -> String:
		return "user://config"


	func get_self_contained_file() -> String:
		return ""


	func is_self_contained() -> bool:
		return false


var distraction_free_mode: bool:
	set(v):
		__base_control.distraction_free_mode = v
	get:
		return __base_control.distraction_free_mode

var __standalone_paths = StandalonePaths.new()
var __base_control: Control
var __editor_main_screen_holder: VBoxContainer
var __select_main_screen_callback: Callable
var __set_plugin_enabled_callback: Callable


func edit_node(node: Node) -> void:
	pass


func edit_resource(resource: Resource) -> void:
	pass


func edit_script(script: Script, line: int = -1, grab_focus: bool = true) -> void:
	pass


func get_base_control() -> Control:
	return __base_control


func get_command_palette():
	return null


func get_current_path() -> String:
	return "user://"


func get_edited_scene_root() -> Node:
	return null


func get_editor_main_screen() -> VBoxContainer:
	return __editor_main_screen_holder


func get_editor_paths():
	return __standalone_paths


func get_editor_scale() -> float:
	return 1.0


func get_editor_settings():
	return null


func get_file_system_dock():
	return null


func get_inspector():
	return null


func get_open_scenes() -> PackedStringArray:
	return PackedStringArray([])


func get_playing_scene() -> String:
	return ""


func get_resource_filesystem():
	return null


func get_resource_previewer():
	return null


func get_script_editor():
	return null


func get_selected_path():
	"user://"


func get_selection():
	return null


func inspect_object(object: Object, for_property: String = "", inspector_only: bool = false):
	pass


func is_playing_scene() -> bool:
	return false


func is_plugin_enabled(plugin: String) -> bool:
	var splg = ProjectSettings.get_setting(Env.installed_plugins_key)
	for cfg in splg:
		if cfg.get_base_dir().get_file() == plugin:
			return true
	return false


func make_mesh_previews(meshes: Array[Mesh], preview_size: int) -> Array[Texture2D]:
	var res: Array[Texture2D] = []
	for mesh in meshes:
		res.append(PlaceholderTexture2D.new())
		res[len(res) - 1].set_size(Vector2(preview_size, preview_size))
	return res


func open_scene_from_path(scene_filepath: String) -> void:
	pass


func play_current_scene() -> void:
	pass


func play_custom_scene(scene_filepath: String) -> void:
	pass


func play_main_scene() -> void:
	pass


func reload_scene_from_path(scene_filepath: String) -> void:
	pass


func restart_editor(save: bool = true):
	# TODO this could be implemented.
	pass


func save_scene() -> int:
	return OK


func save_scene_as(path: String, with_preview: bool = true) -> void:
	pass


func select_file(file: String) -> void:
	pass


func set_main_screen_editor(name: String) -> void:
	__select_main_screen_callback.call(name)


func set_plugin_enabled(plugin: String, enabled: bool) -> void:
	__set_plugin_enabled_callback.call(plugin, enabled)


func stop_playing_scene() -> void:
	pass
