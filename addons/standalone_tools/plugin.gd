@tool
extends EditorPlugin

## The tooling to make plugins standalone.
##
## - makes builds possible by injecting needed scripts
## - contains tooling to make development better
##
## This needs to create a zip file. As godot can not do this 7-Zip is needed.
## Once godotengine/godot#65281 is merged this should be reworked. (The feature
## is confirmed as far as i understand.)
# Most of the logic is placed inside the export plugin to group helper functions
# at one place.


const ExportPlugin := preload("./export_plugin.gd")
var export_plugin_instance = ExportPlugin.new()

const tool_menu_make_standalone: String = "Make plugin standalone"


func _enter_tree() -> void:
	add_export_plugin(export_plugin_instance)
	add_tool_menu_item(tool_menu_make_standalone, show_plugin_select_popup.bind(
		make_plugin_standalone
	))


func _exit_tree() -> void:
	remove_export_plugin(export_plugin_instance)
	remove_tool_menu_item(tool_menu_make_standalone)


func _build() -> bool:
	return export_plugin_instance.generate()


func make_plugin_standalone(plugin: String) -> void:
	var cfg = ConfigFile.new()
	var res = cfg.load(plugin)
	if res != OK:
		print("The plugins path is wrong.")
		return
	var path = plugin.get_base_dir().path_join(
		cfg.get_value("plugin", "script", "")
	)
	if not FileAccess.file_exists(path):
		print("The main script does not exist.")
		return
	var script = load(path)
	if not script is Script:
		print("The main script is not a script.")
		return
	while script.get_base_script() != null:
		script = script.get_base_script()
	if script.source_code.begins_with(ExportPlugin.annotation):
		print("This plugin is already a standalone plugin.")
		return
	if script.get_instance_base_type() != &"EditorPlugin":
		print("The plugins main script does not inherit EditorPlugin.")
		return

	var new_path = "standalone_plugin%s.gd"
	var t = ""
	while FileAccess.file_exists(path.get_base_dir().path_join(new_path % t)):
		if t is int:
			t += 1
		else:
			t = 2
	new_path = new_path % t
	res = DirAccess.copy_absolute(
		Env.editor_implementation,
		path.get_base_dir().path_join(new_path),
	)
	if res != OK:
		print("Copying to of the editor implementation failed.")
		return
	var source = script.get_source_code().split("\n")
	var regex = RegEx.new()
	regex.compile("^(?<full>extends(?<space>\\s+)EditorPlugin)(?<after>(\\s(.|\\s)*)?)$")
	for i in len(source):
		var r = regex.search(source[i])
		if r == null:
			continue
		source[i] = "extends"+r.get_string("space")+'"'+path.get_base_dir().path_join(new_path)+'"'+r.get_string("after")
		break

	var f = FileAccess.open(script.resource_path, FileAccess.WRITE)
	res = f.get_error()
	if res != OK:
		print("Could not save script.")
		return
	f.store_string("\n".join(source))
	f = null
	get_editor_interface().get_resource_filesystem().scan()
	# TODO find a way to reload the scripts in the script editor
	print("Script generation successfull.")


## Returns all plugins that are installed.
## (Searching in [code]res://addons[/code])
func get_installed_plugins() -> PackedStringArray:
	const addons_dir := "res://addons"
	const config_file := "plugin.cfg"
	var res: PackedStringArray = []

	for dir in DirAccess.get_directories_at(addons_dir):
		var path = addons_dir.path_join(dir).path_join(config_file)
		if FileAccess.file_exists(path):
			res.append(path)

	return res


## Creates and shows a popup that allows selection of an installed plugin.
## If a plugin was choosen callback will be called with the path to the config
## file of this plugin.
func show_plugin_select_popup(callback: Callable) -> void:
	var plugins := get_installed_plugins()

	# Lambdas do not support [code]bind[/code]. This is a workaround to bind to
	# a lambda.
	var bind_factory = func(path):
		return func(): callback.call(path)

	var popup = AcceptDialog.new()
	popup.exclusive = true
	popup.get_ok_button().text = tr("Cancel")
	popup.title = "Select a plugin"

	var vbox := VBoxContainer.new()
	popup.add_child(vbox)

	for plg in plugins:
		# Skip this plugin, as it is not meant to run standalone.
		if plg.get_base_dir() == get_script().resource_path.get_base_dir():
			continue

		var cfg = ConfigFile.new()
		var res = cfg.load(plg)
		if res != OK:
			continue
		var btn = Button.new()
		btn.pressed.connect(bind_factory.call(plg))
		btn.pressed.connect(popup.hide)
		btn.text = cfg.get_value("plugin", "name")
		vbox.add_child(btn)

	get_editor_interface().get_base_control().add_child(popup)
	popup.popup_centered(Vector2i(400, 0))
	popup.visibility_changed.connect(popup.queue_free)
