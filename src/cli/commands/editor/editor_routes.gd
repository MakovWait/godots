class_name EditorsRoutes
extends Routes.List

func _init(ctx: CliContext) -> void:
	self._items = [
		OpenEditor.Route.new(ctx),
		EditorCfgCommand.Route.new(ctx),
		EditorListCommand.Route.new(ctx)
	]

func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
	return cmd.namesp == "editor" and super.match(cmd, user_args)
