class_name EditorsRoutes
extends Routes.List

func _init() -> void:
	self._items = [
		OpenEditor.Route.new()
	]

func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
	return cmd.namesp == "editor" and super.match(cmd, user_args)
