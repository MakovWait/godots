extends "res://addons/gd-plug/plug.gd"


func _plugging():
	plug("MikeSchulze/gdUnit4", {"commit": "353946d7e345d4e6cb05c338be667d73c6da5575"})
	plug("MakovWait/godot-use-context")
	
	if "--include-editor" in OS.get_cmdline_args():
		plug("MakovWait/godot-expand-region", {"exclude": ["addons/gdUnit4"]})
		plug("MakovWait/godot-find-everywhere")
		plug("MakovWait/godot-previous-tab")
		plug("MakovWait/godot-script-tabs")
