extends Node

@export_file() var gui_scene_path: String

func _ready() -> void:
	var args := OS.get_cmdline_args()
	var user_args := OS.get_cmdline_user_args()

	if _is_cli_mode(args):
		Output.push("Run cli mode")
		var adjusted_args := args.slice(1) if OS.has_feature("editor") else args
		CliMain.main(adjusted_args, user_args)
		_exit()
	else:
		Output.push("Run window mode")
		add_child.call_deferred((load(gui_scene_path) as PackedScene).instantiate())
	pass

func _is_cli_mode(args: PackedStringArray) -> bool:
	if args.size() > 1 and OS.has_feature("editor"):
		return true
	elif args.size() >= 1 and OS.has_feature("template"):
		return true
	return false

func _exit() -> void:
	get_tree().quit()
