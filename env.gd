class_name Env

## Contains environment information which is needed both for generation and
## execution.


## The directory in which to place generated files.
const generated_dir: String = "res://generated"

## The name of the resource pack which injects the standalone script.
const resource_pack_name: String = "inject.zip"

## Key for the ProjectSettings under which the standalone plugins are listed.
const installed_plugins_key: String = "editor_plugins/standalone/installed"
const enabled_plugins_key: String = "editor_plugins/standalone/enabled"
const override_settings_path: String = "override.cfg"

## The path to the script which is injected on runtime.
const standalone_implementation: String = "res://standalone_plugin/inject.gd"
const editor_implementation: String = "res://standalone_plugin/editor.gd"
