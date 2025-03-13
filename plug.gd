@tool
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	plug("MikeSchulze/gdUnit4", {"commit": "8226bc34faaa9fde7829b065fa51b63a8fe140c4"})
	plug("MakovWait/godot-use-context")

	if "--include-editor" in OS.get_cmdline_args():
		plug("MakovWait/godot-expand-region", {"exclude": ["addons/gdUnit4"]})
		plug("MakovWait/godot-find-everywhere")
		plug("MakovWait/godot-previous-tab")
		plug("MakovWait/godot-script-tabs")
