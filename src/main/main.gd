extends Node

func _ready():
	var args = OS.get_cmdline_args()
	var user_args = OS.get_cmdline_user_args()

	if _is_cli_mode(args):
		Output.push("Run cli mode")
		CliMain.main(args, user_args)
		_exit()
	else:
		Output.push("Run window mode")
		add_child.call_deferred(load("res://src/main/win_main.tscn").instantiate())
	pass

func _is_cli_mode(args: PackedStringArray) -> bool:
	if args.size() > 1 and not OS.has_feature("template"):
		return true
	elif args.size() >= 1 and OS.has_feature("template"):
		return true
	return false

func _exit():
	get_tree().quit()
