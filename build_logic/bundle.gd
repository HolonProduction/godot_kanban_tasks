@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	load("res://build_logic/bundle_release.gd").new().bundle_release()
