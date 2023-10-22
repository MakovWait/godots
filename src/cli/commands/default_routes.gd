class_name DefaultRoutes
extends Routes.List

func _init():
	self._items = [
		Help.Route.new(),
		OpenRecentProject.Route.new()
	]

func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
	return (cmd.namesp == "" and cmd.verb == "" and 
		super.match(cmd, user_args))
