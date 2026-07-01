@tool
extends RefCounted

const LICENSES_TEMPLATE := """------------------------------------------------------------------------------------------------------------
Kanban Tasks - Todo Manager is released under the MIT license:
------------------------------------------------------------------------------------------------------------

$LICENSE$

------------------------------------------------------------------------------------------------------------
Kanban Tasks - Todo Manager relies on software published under the following licenses:
------------------------------------------------------------------------------------------------------------
Godot UUID

$UUID_LICENSE$

------------------------------------------------------------------------------------------------------------
Godot Engine

$GODOT_LICENSE$

------------------------------------------------------------------------------------------------------------
Godot Engine relies on third party software which is released under compatible licenses.
More information can be found here:
https://godotengine.org/license/
https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt
"""

const BUILD_DIR := "res://export/"

var version: String

var working_dir: String
var output_dir: String

## The timestamp to use for packed zip file creation date.
## Queried once when the assembly is started for consistency.
var time: int = 0

func read(path: String) -> String:
	var acc := FileAccess.open(path, FileAccess.READ)
	check(is_instance_valid(acc))
	return acc.get_as_text()

func store(path: String, content: String) -> void:
	var acc := FileAccess.open(path, FileAccess.WRITE)
	check(is_instance_valid(acc))
	return acc.store_string(content)

func check(cond: bool) -> void:
	if not cond:
		push_error("Build failed.")
		print_stack()

var strip_ansii_regex := RegEx.create_from_string("\u001b\\[((?:\\d|;)*)([a-zA-Z])")
func strip_ansii(output: String) -> String:
	return strip_ansii_regex.sub(output, "", true)


func pack_dir(zip: ZIPPacker, dir: String, at: String, filter: Callable = func(_arg): return true):
	var acc := DirAccess.open(dir)
	acc.include_hidden = true
	acc.include_navigational = false
	check(is_instance_valid(acc))
	
	for file in acc.get_files():
		if not filter.call(dir.path_join(file)):
			continue
		
		check(zip.start_file(at.path_join(file), FileAccess.get_unix_permissions(dir.path_join(file)), time) == OK)
		check(zip.write_file(FileAccess.get_file_as_bytes(dir.path_join(file))) == OK)
		check(zip.close_file() == OK)
	
	for sub_dir in acc.get_directories():
		if not filter.call(dir.path_join(sub_dir)):
			continue
		pack_dir(zip, dir.path_join(sub_dir), at.path_join(sub_dir), filter)

func pack_file(zip: ZIPPacker, file: String, at: String) -> void:
	check(zip.start_file(at, FileAccess.get_unix_permissions(file), time) == OK)
	check(zip.write_file(FileAccess.get_file_as_bytes(file)) == OK)
	check(zip.close_file() == OK)

func remove_dir(dir: String):
	var acc := DirAccess.open(dir)
	if not acc:
		return
	acc.include_hidden = true
	acc.include_navigational = false
	for sub_dir in acc.get_directories():
		remove_dir(dir.path_join(sub_dir))
		acc.remove(sub_dir)
	for file in acc.get_files():
		acc.remove(file)
	DirAccess.remove_absolute(dir)


func make_license_file() -> void:
	var license := read("res://LICENSE")
	var uuid_license := read("res://addons/kanban_tasks/uuid/LICENSE")
	var godot_license := Engine.get_license_text()
	
	var content := LICENSES_TEMPLATE
	content = content.replace("$LICENSE$", license.rstrip("\n"))
	content = content.replace("$UUID_LICENSE$", uuid_license.rstrip("\n"))
	content = content.replace("$GODOT_LICENSE$", godot_license.rstrip("\n"))
	
	store(working_dir.path_join("licenses.txt"), content)


func get_version() -> void:
	var cfg := ConfigFile.new()
	check(cfg.load("res://addons/kanban_tasks/plugin.cfg") == OK)
	version = cfg.get_value("plugin", "version")
	version = version.strip_edges().trim_prefix("v")
	check(not version.is_empty())


func prepare_output_dir() -> void:
	remove_dir(output_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)


func bundle_addon() -> void:
	var writer := ZIPPacker.new()
	writer.compression_level = ZIPPacker.COMPRESSION_BEST
	
	var root_folder := "kanban_tasks_v" + version + "_addon"
	
	check(writer.open(output_dir.path_join(root_folder + ".zip")) == OK)
	
	pack_dir(writer, "res://addons/kanban_tasks/", root_folder.path_join("addons/kanban_tasks/"))
	# Bundle the license with the addon.
	pack_file(writer, "res://LICENSE", root_folder.path_join("addons/kanban_tasks/LICENSE"))
	
	check(writer.close() == OK)


func bundle_standalone(template: String, platform: String, bin_ext: String) -> void:
	var export_dir := ProjectSettings.globalize_path(working_dir.path_join(platform))
	DirAccess.make_dir_absolute(export_dir)
	
	var args := PackedStringArray()
	args.push_back("--no-header")
	args.push_back("--headless")
	args.push_back("--export-release")
	args.push_back(template)
	args.push_back(export_dir.path_join("kanban_tasks." + bin_ext))
	
	var out := []
	check(OS.execute(OS.get_executable_path(), args, out, true) == 0)
	print(strip_ansii(out[0]))
	
	var writer := ZIPPacker.new()
	writer.compression_level = ZIPPacker.COMPRESSION_BEST
	
	var root_folder := "kanban_tasks_v" + version + "_" + platform
	
	check(writer.open(output_dir.path_join(root_folder + ".zip")) == OK)
	
	pack_dir(writer, export_dir, root_folder)
	pack_file(writer, working_dir.path_join("licenses.txt"), root_folder.path_join("licenses.txt"))
	
	check(writer.close() == OK)


func bundle_release():
	time = int(Time.get_unix_time_from_system())
	
	var acc := DirAccess.create_temp("godot_kanban_tasks_build")
	working_dir = acc.get_current_dir()
	
	get_version()
	output_dir = BUILD_DIR.path_join("v" + version)
	
	prepare_output_dir()
	
	bundle_addon()
	
	make_license_file()
	
	# TODO: Update windows metadata based on plugin version.
	
	bundle_standalone("Linux/X11", "linux", "x86_64")
	bundle_standalone("Windows Desktop", "windows", "exe")
