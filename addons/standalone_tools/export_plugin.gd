@tool
extends EditorExportPlugin


const annotation := "#@standalone\n"
const enabled_plugins_key := "editor_plugins/enabled"


func _get_name() -> String:
	return "StandaloneTools"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	generate()

	# Include all generated files in export.
	include_recursive(Env.generated_dir)

	# Include all standalone plugins in export.
	for cfg in ProjectSettings.get(Env.installed_plugins_key):
		include_recursive(cfg.get_base_dir())


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	# Skip all files that are part of this plugin as this plugin only contains
	# build logic and no runtime components.
	var plugin_path = get_script().resource_path.get_base_dir()
	if path.get_base_dir().begins_with(plugin_path):
		skip()


## Ensures, that this file is included in the export.
## This uses add_file internaly. Influence on size for files that would already
## be exported is yet to test.
func include_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	add_file(path, file.get_buffer(file.get_length()), false)


## Includes a file or folder and everything, that is in it.
func include_recursive(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for i in DirAccess.get_directories_at(path):
			include_recursive(path.path_join(i))
		for i in DirAccess.get_files_at(path):
			include_recursive(path.path_join(i))
	elif FileAccess.file_exists(path):
		include_file(path)


## Removes a file or directory recursively.
## The path should be absolute.
func remove_recursive(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for i in DirAccess.get_directories_at(path):
			remove_recursive(path.path_join(i))
		for i in DirAccess.get_files_at(path):
			remove_recursive(path.path_join(i))
	DirAccess.remove_absolute(path)


## Generates the needed files for standalone execution.
func generate() -> bool:
	# The path of this script.
	var path: String = get_script().resource_path.get_base_dir()

	# Extract plugins that should be included in standalone build.

	# The script to inject
	var standalone_content: PackedByteArray
	var f = FileAccess.open(Env.standalone_implementation, FileAccess.READ)
	standalone_content = f.get_as_text().to_utf8_buffer()

	# The paths to the plugins .cfg files
	var cfg_paths: PackedStringArray = []
	# The paths of scripts inheriting EditorPlugin
	var script_paths: PackedStringArray = []

	for cfg in ProjectSettings.get_setting(enabled_plugins_key):
		var file = ConfigFile.new()
		file.load(cfg)

		var script: Script = load(
			cfg.get_base_dir().path_join(file.get_value("plugin", "script")),
		)
		if (
			script.get_base_script() and
			script.get_base_script().source_code.begins_with(annotation)
		):
			cfg_paths.append(cfg)
			script_paths.append(script.get_base_script().resource_path)

	# Store the standalone plugins in the project settings for runtime loading
	ProjectSettings.set_setting(Env.installed_plugins_key, cfg_paths)
	ProjectSettings.set_setting(Env.enabled_plugins_key, [])
	ProjectSettings.save()

	if not DirAccess.dir_exists_absolute(Env.generated_dir):
		DirAccess.make_dir_recursive_absolute(Env.generated_dir)

	remove_recursive(
		Env.generated_dir.path_join(Env.resource_pack_name),
	)

	remove_recursive(
		Env.override_settings_path,
	)

	var writer = ZIPPacker.new()
	var res = writer.open(Env.generated_dir.path_join(Env.resource_pack_name))
	if res != OK:
		print("Saving resource pack failed: ", res)

	writer.start_file("addons/")
	writer.close_file()

	for p in script_paths:
		if p.begins_with("res://"):
			var without_res = p.substr(len("res://"))
			writer.start_file(without_res)
			writer.write_file(standalone_content)
			writer.close_file()

	res = writer.close()

	return true
