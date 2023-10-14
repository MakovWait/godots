extends "res://addons/gd-plug/plug.gd"


func _plugging():
	plug("MakovWait/godot-expand-region", {"exclude": ["addons/gdUnit4"]})
	plug("MakovWait/godot-find-everywhere")
	plug("MakovWait/godot-previous-tab")
	plug("MakovWait/godot-script-tabs")
